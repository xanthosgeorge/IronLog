import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DashboardPageComponent } from './dashboard-page.component';
import { of, throwError } from 'rxjs';
import { Chart } from 'chart.js';
import { ExerciseService } from '../../../exercises/services/exercise.service';
import { WorkoutSessionService } from '../../../workout-sessions/services/workout-session.service';
import { WorkoutSession, WorkoutSet } from '../../../workout-sessions/models/workout-session.model';

describe('DashboardPageComponent', () => {
  let component: DashboardPageComponent;
  let fixture: ComponentFixture<DashboardPageComponent>;
  let workoutService: jasmine.SpyObj<WorkoutSessionService>;
  const exercise = { id: 'bench', name: 'Bench Press', muscleGroupId: 'chest', muscleGroupName: 'Chest', isActive: true };
  const set = (weight: number | undefined, reps = 8, isWarmup = false): WorkoutSet => ({ id: 'set', setNumber: 1, weight, reps, isWarmup });
  const session = (id: string, date: string, sets: WorkoutSet[], exerciseId = 'bench'): WorkoutSession => ({
    id, title: id, sessionDate: date,
    exercises: [{ id: 'exercise', exerciseId, exerciseName: 'Bench Press', orderIndex: 1, sets }]
  });

  beforeEach(async () => {
    localStorage.removeItem('ironlog.preferences');
    workoutService = jasmine.createSpyObj('WorkoutSessionService', ['getAll', 'getById']);
    const history = [
      session('latest', '2026-10-12T10:00:00Z', [set(65), set(100, 8, true)]),
      session('first', '2026-10-05T10:00:00Z', [set(50), set(60)]),
      session('other', '2026-10-07T10:00:00Z', [set(200)], 'squat')
    ];
    workoutService.getAll.and.returnValue(of(history));
    workoutService.getById.and.callFake(id => of(history.find(item => item.id === id)!));
    await TestBed.configureTestingModule({
      imports: [DashboardPageComponent],
      providers: [
        { provide: ExerciseService, useValue: { getAll: () => of([exercise]) } },
        { provide: WorkoutSessionService, useValue: workoutService }
      ]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DashboardPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => {
    fixture.destroy();
    localStorage.removeItem('ironlog.preferences');
  });

  it('updates chart colors and labels when preferences change', () => {
    component.preferences.setTheme('blue');
    component.preferences.setLanguage('el');
    fixture.detectChanges();
    const chart = Chart.getChart(fixture.nativeElement.querySelector('canvas'))!;
    expect(chart.data.datasets[0].borderColor).toBe('#80baff');
    expect(chart.data.datasets[0].label).toBe('Μέγιστο βάρος σετ');
    expect(fixture.nativeElement.querySelector('h1').textContent).toBe('Πρόοδος άσκησης');
  });

  it('sorts history and compares working weights without warmups or other exercises', () => {
    expect(component.points.map(point => point.value)).toEqual([60, 65]);
    expect(component.change).toBeCloseTo(8.3333, 3);
    expect(workoutService.getById).toHaveBeenCalledTimes(3);
  });

  it('calculates volume and repetitions from working sets', () => {
    component.metric = 'volume';
    component.updateProgress();
    expect(component.points.map(point => point.value)).toEqual([880, 520]);
    expect(component.change).toBeLessThan(0);
    component.metric = 'reps';
    component.updateProgress();
    expect(component.points.map(point => point.value)).toEqual([8, 8]);
    expect(component.change).toBe(0);
  });

  it('does not claim improvement for a single workout or a zero baseline', () => {
    workoutService.getAll.and.returnValue(of([session('single', '2026-10-05', [set(0)])]));
    workoutService.getById.and.returnValue(of(session('single', '2026-10-05', [set(0)])));
    component.load();
    expect(component.points.length).toBe(1);
    expect(component.change).toBeNull();
    component.points.push({ date: '2026-10-12', title: 'next', value: 10 });
    expect(component.change).toBeNull();
  });

  it('supports unweighted exercise repetitions without inventing a weight', () => {
    workoutService.getAll.and.returnValue(of([session('bodyweight', '2026-10-05', [set(undefined, 12)])]));
    workoutService.getById.and.returnValue(of(session('bodyweight', '2026-10-05', [set(undefined, 12)])));
    component.load();
    expect(component.points).toEqual([]);
    component.metric = 'reps';
    component.updateProgress();
    expect(component.points[0].value).toBe(12);
  });

  it('shows a recoverable error when workout details cannot be loaded', () => {
    workoutService.getById.and.returnValue(throwError(() => new Error('offline')));
    component.load();
    expect(component.loading).toBeFalse();
    expect(component.error).toBeTruthy();
  });
});
