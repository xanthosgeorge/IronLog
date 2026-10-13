import { AfterViewInit, Component, DestroyRef, ElementRef, OnDestroy, OnInit, ViewChild, effect, inject } from '@angular/core';
import { PreferencesService } from '../../../../core/preferences/preferences.service';
import { TranslatePipe, LocalDatePipe, LocalNumberPipe } from '../../../../core/preferences/translate.pipe';
import { FormsModule } from '@angular/forms';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { forkJoin, from, mergeMap, of, switchMap, toArray } from 'rxjs';
import { Chart, CategoryScale, LinearScale, LineController, LineElement, PointElement, Tooltip, Filler } from 'chart.js';
import { ExerciseService } from '../../../exercises/services/exercise.service';
import { Exercise } from '../../../exercises/models/exercise.model';
import { WorkoutSessionService } from '../../../workout-sessions/services/workout-session.service';
import { WorkoutSession } from '../../../workout-sessions/models/workout-session.model';

Chart.register(CategoryScale, LinearScale, LineController, LineElement, PointElement, Tooltip, Filler);

type ProgressMetric = 'weight' | 'reps' | 'volume';
interface ProgressPoint { date: string; title: string; value: number; }

@Component({
  selector: 'app-dashboard-page',
  imports: [FormsModule, TranslatePipe, LocalDatePipe, LocalNumberPipe],
  templateUrl: './dashboard-page.component.html',
  styleUrl: './dashboard-page.component.scss'
})
export class DashboardPageComponent implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild('progressCanvas', { static: true }) canvas!: ElementRef<HTMLCanvasElement>;
  private readonly destroyRef = inject(DestroyRef);
  readonly preferences = inject(PreferencesService);
  private chart?: Chart<'line', number[], string>;
  private sessions: WorkoutSession[] = [];
  exercises: Exercise[] = [];
  selectedExerciseId = '';
  metric: ProgressMetric = 'weight';
  points: ProgressPoint[] = [];
  loading = true;
  error = '';

  constructor(private exerciseService: ExerciseService, private workoutService: WorkoutSessionService) {
    effect(() => {
      this.preferences.language();
      this.preferences.theme();
      this.renderChart();
    });
  }

  get selectedExercise(): Exercise | undefined {
    return this.exercises.find(exercise => exercise.id === this.selectedExerciseId);
  }
  get metricLabel(): string {
    return this.preferences.translate({ weight: 'Max working weight', reps: 'Max reps per set', volume: 'Training volume' }[this.metric]);
  }
  get unit(): string { return this.metric === 'reps' ? this.preferences.translate('reps') : 'kg'; }
  get first(): ProgressPoint | undefined { return this.points[0]; }
  get latest(): ProgressPoint | undefined { return this.points[this.points.length - 1]; }
  get change(): number | null {
    if (this.points.length < 2 || !this.first || this.first.value === 0) return null;
    return ((this.latest!.value - this.first.value) / this.first.value) * 100;
  }

  ngOnInit(): void { this.load(); }
  ngAfterViewInit(): void { this.renderChart(); }
  ngOnDestroy(): void { this.chart?.destroy(); }

  load(): void {
    this.loading = true;
    this.error = '';
    forkJoin({
      exercises: this.exerciseService.getAll(),
      sessions: this.workoutService.getAll().pipe(
        switchMap(sessions => sessions.length
          ? from(sessions).pipe(mergeMap(session => this.workoutService.getById(session.id), 6), toArray())
          : of([] as WorkoutSession[]))
      )
    }).pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
      next: ({ exercises, sessions }) => {
        this.exercises = [...exercises].sort((a, b) => a.name.localeCompare(b.name));
        this.sessions = [...sessions].sort((a, b) => Date.parse(a.sessionDate) - Date.parse(b.sessionDate));
        if (!this.exercises.some(exercise => exercise.id === this.selectedExerciseId)) {
          this.selectedExerciseId = this.exercises.find(exercise =>
            this.sessions.some(session => session.exercises.some(item => item.exerciseId === exercise.id)))?.id
            ?? this.exercises[0]?.id ?? '';
        }
        this.loading = false;
        this.updateProgress();
      },
      error: () => {
        this.loading = false;
        this.error = 'Could not load your exercise history.';
      }
    });
  }

  updateProgress(): void {
    this.points = this.sessions.flatMap(session => {
      const sets = session.exercises.filter(exercise => exercise.exerciseId === this.selectedExerciseId)
        .flatMap(exercise => exercise.sets)
        .filter(set => !set.isWarmup && set.reps > 0);
      const weightedSets = sets.filter(set => set.weight != null && Number.isFinite(set.weight) && set.weight! >= 0);
      if (!(this.metric === 'reps' ? sets : weightedSets).length) return [];
      const value = this.metric === 'reps' ? Math.max(...sets.map(set => set.reps))
        : this.metric === 'weight' ? Math.max(...weightedSets.map(set => set.weight!))
        : weightedSets.reduce((sum, set) => sum + set.weight! * set.reps, 0);
      return [{ date: session.sessionDate, title: session.title, value }];
    });
    this.renderChart();
  }

  private renderChart(): void {
    if (!this.canvas) return;
    this.chart?.destroy();
    this.chart = undefined;
    if (!this.points.length) return;
    this.chart = new Chart(this.canvas.nativeElement, {
      type: 'line',
      data: {
        labels: this.points.map(point => new Date(point.date).toLocaleDateString(this.preferences.locale(), { month: 'short', day: 'numeric' })),
        datasets: [{
          label: this.metricLabel, data: this.points.map(point => point.value),
          borderColor: this.preferences.palette().soft, backgroundColor: `rgba(${this.preferences.palette().rgb}, 0.12)`,
          pointBackgroundColor: this.preferences.palette().soft, pointBorderColor: '#171a21', pointBorderWidth: 2,
          borderWidth: 3, pointRadius: 5, pointHoverRadius: 7, fill: true, tension: 0
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false, animation: false,
        interaction: { mode: 'index', intersect: false },
        plugins: { tooltip: { callbacks: {
          title: items => {
            const point = this.points[items[0].dataIndex];
            return new Date(point.date).toLocaleDateString(this.preferences.locale()) + ' - ' + point.title;
          },
          label: item => this.metricLabel + ': ' + item.parsed.y?.toLocaleString(this.preferences.locale()) + ' ' + this.unit
        } } },
        scales: {
          x: { grid: { display: false }, ticks: { color: '#a5acb8', maxTicksLimit: 6, maxRotation: 0 } },
          y: {
            beginAtZero: true, grid: { color: 'rgba(255,255,255,0.07)' },
            title: { display: true, text: this.unit, color: '#a5acb8' },
            ticks: { color: '#a5acb8', precision: this.metric === 'reps' ? 0 : undefined }
          }
        }
      }
    });
  }
}
