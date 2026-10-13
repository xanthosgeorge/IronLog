import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of, Subject } from 'rxjs';
import { WorkoutSessionsPageComponent } from './workout-sessions-page.component';
import { WorkoutSessionService } from '../../services/workout-session.service';
import { ExerciseService } from '../../../exercises/services/exercise.service';
import { WorkoutSession } from '../../models/workout-session.model';

describe('WorkoutSessionsPageComponent', () => {
  let fixture: ComponentFixture<WorkoutSessionsPageComponent>;
  let component: WorkoutSessionsPageComponent;
  let service: jasmine.SpyObj<WorkoutSessionService>;
  let response: Subject<{ id: string }>;
  const session: WorkoutSession = {
    id: 'session', title: 'Upper A', sessionDate: '2026-10-05T14:00:00Z', totalVolume: 1440,
    exercises: [{ id: 'item', exerciseId: 'bench', exerciseName: 'Bench Press', orderIndex: 1,
      sets: [{ id: 'set', setNumber: 1, weight: 60, reps: 8, isWarmup: false }] }]
  };

  beforeEach(async () => {
    service = jasmine.createSpyObj('WorkoutSessionService', ['getAll', 'getById', 'create']);
    response = new Subject();
    service.getAll.and.returnValue(of([session]));
    service.getById.and.returnValue(of(session));
    service.create.and.returnValue(response);
    await TestBed.configureTestingModule({
      imports: [WorkoutSessionsPageComponent],
      providers: [
        { provide: WorkoutSessionService, useValue: service },
        { provide: ExerciseService, useValue: { getAll: () => of([{ id: 'bench', name: 'Bench Press', muscleGroupName: 'Chest', isActive: true }]) } }
      ]
    }).compileComponents();
    fixture = TestBed.createComponent(WorkoutSessionsPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });
  afterEach(() => fixture.destroy());

  it('shows workouts in a table and opens the form only on demand', () => {
    expect(fixture.nativeElement.querySelectorAll('.data-table tbody tr').length).toBe(1);
    expect(component.dialog.nativeElement.open).toBeFalse();
    (fixture.nativeElement.querySelector('.page-header button') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(document.activeElement).toBe(component.dialog.nativeElement.querySelector('input[name="title"]'));
  });

  it('preserves multiple exercises and sets in the payload and closes after saving', () => {
    component.openCreateDialog();
    const first = component.form.exercises[0];
    first.sets[0].weight = 60;
    first.sets[0].reps = 8;
    component.addSet(first);
    first.sets[1].weight = 20;
    first.sets[1].reps = 12;
    first.sets[1].isWarmup = true;
    component.addExercise();
    component.form.exercises[1].sets[0].reps = 10;
    component.save();
    component.save();
    expect(service.create).toHaveBeenCalledTimes(1);
    const payload = service.create.calls.mostRecent().args[0];
    expect(payload.exercises.length).toBe(2);
    expect(payload.exercises[0].sets.map(set => set.setNumber)).toEqual([1, 2]);
    expect(payload.exercises[0].sets[1].isWarmup).toBeTrue();
    expect(payload.exercises[1].orderIndex).toBe(2);
    expect(component.dialog.nativeElement.open).toBeTrue();
    response.next({ id: 'new' });
    expect(component.dialog.nativeElement.open).toBeFalse();
    expect(service.getAll).toHaveBeenCalledTimes(2);
    expect(component.successMessage).toBeTruthy();
  });

  it('retains the workout form when the API rejects a save', () => {
    component.openCreateDialog();
    component.form.title = 'Unsaved workout';
    component.form.exercises[0].sets[0].reps = 8;
    component.save();
    response.error(new Error('offline'));
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(component.form.title).toBe('Unsaved workout');
    expect(component.isSaving).toBeFalse();
    expect(component.errorMessage).toBeTruthy();
  });

  it('validates sets before submitting and blocks dismissal during a pending save', () => {
    component.openCreateDialog();
    component.save();
    expect(service.create).not.toHaveBeenCalled();
    component.form.exercises[0].sets[0].reps = 8;
    component.save();
    fixture.detectChanges();
    component.closeDialog();
    const cancel = new Event('cancel', { cancelable: true });
    component.dialog.nativeElement.dispatchEvent(cancel);
    expect(cancel.defaultPrevented).toBeTrue();
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect((component.dialog.nativeElement.querySelector('fieldset') as HTMLFieldSetElement).disabled).toBeTrue();
  });

  it('allows cancellation and starts with a fresh form next time', () => {
    component.openCreateDialog();
    component.form.title = 'Discarded';
    component.addExercise();
    component.closeDialog();
    expect(component.dialog.nativeElement.open).toBeFalse();
    component.openCreateDialog();
    expect(component.form.title).toBe('Upper A');
    expect(component.form.exercises.length).toBe(1);
  });

  it('opens workout details independently of the registration form', () => {
    component.viewDetails(session);
    fixture.detectChanges();
    expect(service.getById).toHaveBeenCalledWith(session.id);
    expect(component.detailsDialog.nativeElement.open).toBeTrue();
    expect(component.dialog.nativeElement.open).toBeFalse();
    expect(component.detailsDialog.nativeElement.textContent).toContain('Bench Press');
  });
});
