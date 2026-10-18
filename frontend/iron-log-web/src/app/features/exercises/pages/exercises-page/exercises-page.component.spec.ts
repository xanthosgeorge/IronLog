import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ExercisesPageComponent } from './exercises-page.component';
import { of, Subject } from 'rxjs';
import { ExerciseService } from '../../services/exercise.service';
import { MuscleGroupService } from '../../../muscle-groups/services/muscle-group.service';
import { Exercise } from '../../models/exercise.model';

describe('ExercisesPageComponent', () => {
  let component: ExercisesPageComponent;
  let fixture: ComponentFixture<ExercisesPageComponent>;
  let exerciseService: jasmine.SpyObj<ExerciseService>;
  let response: Subject<unknown>;
  const exercise: Exercise = { id: 'bench', name: 'Bench Press', muscleGroupId: 'chest', muscleGroupName: 'Chest', isActive: true };

  beforeEach(async () => {
    exerciseService = jasmine.createSpyObj('ExerciseService', ['getAll', 'create', 'update']);
    response = new Subject();
    exerciseService.getAll.and.returnValue(of([exercise]));
    exerciseService.create.and.returnValue(response as Subject<Exercise>);
    exerciseService.update.and.returnValue(response as Subject<void>);
    await TestBed.configureTestingModule({
      imports: [ExercisesPageComponent],
      providers: [
        { provide: ExerciseService, useValue: exerciseService },
        { provide: MuscleGroupService, useValue: { getAll: () => of([{ id: 'chest', name: 'Chest' }]) } }
      ]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ExercisesPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => fixture.destroy());

  it('combines name, equipment and muscle group filters', () => {
    component.exercises = [exercise,
      { ...exercise, id: 'incline', name: 'Incline Bench Press', equipmentType: 'Dumbbell' },
      { ...exercise, id: 'row', name: 'Bench Row', muscleGroupId: 'back', equipmentType: 'Barbell' }];
    component.exercises[0] = { ...exercise, equipmentType: 'Barbell' };
    component.searchName = '  BENCH  ';
    component.equipmentFilter = 'Barbell';
    component.muscleGroupFilter = 'chest';
    expect(component.filteredExercises.map(x => x.id)).toEqual(['bench']);
    component.clearFilters();
    expect(component.filteredExercises.length).toBe(3);
    expect(component.hasFilters).toBeFalse();
  });

  it('matches names without case or accent differences and offers distinct equipment', () => {
    component.exercises = [
      { ...exercise, name: 'Πιέσεις', equipmentType: ' Barbell ' },
      { ...exercise, id: 'second', equipmentType: 'barbell' },
      { ...exercise, id: 'unset', equipmentType: '' }];
    component.searchName = 'ΠΙΕΣ';
    expect(component.filteredExercises.length).toBe(1);
    expect(component.equipmentOptions.length).toBe(2);
    component.searchName = '';
    component.equipmentFilter = '';
    expect(component.filteredExercises.map(x => x.id)).toEqual(['unset']);
  });

  it('shows a useful empty result and restores the table when filters are cleared', () => {
    const search = fixture.nativeElement.querySelector('input[name="searchName"]') as HTMLInputElement;
    search.value = 'no matching exercise';
    search.dispatchEvent(new Event('input'));
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.data-table')).toBeNull();
    expect(fixture.nativeElement.textContent).toContain('No exercises match your filters.');
    (fixture.nativeElement.querySelector('.clear-filters') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelectorAll('.data-table tbody tr').length).toBe(1);
  });

  it('keeps the form closed until Create Exercise is clicked', () => {
    expect(component.dialog.nativeElement.open).toBeFalse();
    (fixture.nativeElement.querySelector('.page-header button') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(component.form.name).toBe('');
    expect(component.form.muscleGroupId).toBe('chest');
    expect(document.activeElement).toBe(component.dialog.nativeElement.querySelector('input[name="name"]'));
  });

  it('closes only after creation succeeds and refreshes the list', () => {
    component.openCreateDialog();
    component.form.name = 'New exercise';
    component.save();
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(component.isSaving).toBeTrue();
    component.save();
    expect(exerciseService.create).toHaveBeenCalledTimes(1);
    response.next(exercise);
    expect(component.dialog.nativeElement.open).toBeFalse();
    expect(component.isSaving).toBeFalse();
    expect(exerciseService.getAll).toHaveBeenCalledTimes(2);
  });

  it('keeps entered values visible when saving fails', () => {
    component.openCreateDialog();
    component.form.name = 'New exercise';
    component.save();
    response.error(new Error('offline'));
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(component.form.name).toBe('New exercise');
    expect(component.isSaving).toBeFalse();
    expect(component.errorMessage).toBeTruthy();
  });

  it('opens existing exercise details in the same dialog and updates on save', () => {
    component.edit(exercise);
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(component.form.name).toBe(exercise.name);
    component.save();
    expect(exerciseService.update).toHaveBeenCalledWith('bench', jasmine.objectContaining({ name: 'Bench Press' }));
    response.next(undefined);
    expect(component.dialog.nativeElement.open).toBeFalse();
  });

  it('allows cancellation without saving and resets the form when reopened', () => {
    component.openCreateDialog();
    component.form.name = 'Unsaved exercise';
    component.closeDialog();
    expect(component.dialog.nativeElement.open).toBeFalse();
    component.openCreateDialog();
    expect(component.form.name).toBe('');
    expect(exerciseService.create).not.toHaveBeenCalled();
  });

  it('prevents dismissing or changing the dialog while saving', () => {
    component.openCreateDialog();
    component.form.name = 'New exercise';
    component.save();
    fixture.detectChanges();
    component.closeDialog();
    const event = new Event('cancel', { cancelable: true });
    component.dialog.nativeElement.dispatchEvent(event);
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(event.defaultPrevented).toBeTrue();
    expect((component.dialog.nativeElement.querySelector('fieldset') as HTMLFieldSetElement).disabled).toBeTrue();
  });

  it('keeps the dialog open when validation fails', () => {
    component.openCreateDialog();
    component.save();
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(exerciseService.create).not.toHaveBeenCalled();
    expect(component.errorMessage).toBeTruthy();
  });
});
