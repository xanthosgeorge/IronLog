import { PreferencesService } from '../../../../core/preferences/preferences.service';
import { TranslatePipe, LocalDatePipe, LocalNumberPipe } from '../../../../core/preferences/translate.pipe';
import { Component, ElementRef, OnInit, ViewChild, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Exercise } from '../../../exercises/models/exercise.model';
import { ExerciseService } from '../../../exercises/services/exercise.service';
import {
  CreateWorkoutExerciseRequest,
  CreateWorkoutSessionRequest,
  CreateWorkoutSetRequest,
  WorkoutSession
} from '../../models/workout-session.model';
import { WorkoutSessionService } from '../../services/workout-session.service';

interface WorkoutSetForm {
  setNumber: number;
  weight: number | null;
  reps: number | null;
  resistanceNote: string;
  rpe: number | null;
  isWarmup: boolean;
}

interface WorkoutExerciseForm {
  exerciseId: string;
  notes: string;
  sets: WorkoutSetForm[];
}

interface WorkoutSessionForm {
  title: string;
  sessionDate: string;
  durationMinutes: number | null;
  notes: string;
  exercises: WorkoutExerciseForm[];
}

@Component({
  selector: 'app-workout-sessions-page',
  imports: [TranslatePipe, LocalDatePipe, LocalNumberPipe, FormsModule],
  templateUrl: './workout-sessions-page.component.html',
  styleUrl: './workout-sessions-page.component.scss'
})
export class WorkoutSessionsPageComponent implements OnInit {
  @ViewChild('workoutDialog', { static: true }) dialog!: ElementRef<HTMLDialogElement>;
  @ViewChild('detailsDialog', { static: true }) detailsDialog!: ElementRef<HTMLDialogElement>;
  readonly preferences = inject(PreferencesService);
  sessions: WorkoutSession[] = [];
  exercises: Exercise[] = [];
  selectedSession: WorkoutSession | null = null;
  form: WorkoutSessionForm = this.createEmptyForm();
  isLoading = false;
  isLoadingMore = false;
  hasMore = false;
  totalSessions = 0;
  private listVersion = 0;
  isSaving = false;
  errorMessage = '';
  successMessage = '';

  constructor(
    private readonly workoutSessionService: WorkoutSessionService,
    private readonly exerciseService: ExerciseService
  ) {}

  ngOnInit(): void {
    this.loadPageData();
  }

  loadPageData(): void {
    const version = ++this.listVersion;
    this.isLoading = true;
    this.isLoadingMore = false;
    this.errorMessage = '';

    this.exerciseService.getAll().subscribe({
      next: (items) => {
        this.exercises = items.filter((exercise) => exercise.isActive);
        this.ensureDefaultExerciseSelected();
      },
      error: () => {
        this.errorMessage = 'Could not load exercises for the workout form.';
      }
    });

    this.workoutSessionService.getRecent().subscribe({
      next: (page) => {
        if (version !== this.listVersion) return;
        this.sessions = page.items;
        this.totalSessions = page.total;
        this.hasMore = page.hasMore;
        this.isLoading = false;
      },
      error: () => {
        if (version !== this.listVersion) return;
        this.errorMessage = 'Could not load workout sessions from the API.';
        this.isLoading = false;
      }
    });
  }

  loadMore(): void {
    if (this.isLoading || this.isLoadingMore || !this.hasMore) return;
    const version = this.listVersion;
    this.isLoadingMore = true;
    this.errorMessage = '';
    this.workoutSessionService.getRecent(this.sessions.length).subscribe({
      next: page => {
        if (version !== this.listVersion) return;
        const known = new Set(this.sessions.map(x => x.id));
        this.sessions = [...this.sessions, ...page.items.filter(x => !known.has(x.id))];
        this.totalSessions = page.total;
        this.hasMore = page.hasMore;
        this.isLoadingMore = false;
      },
      error: () => {
        if (version !== this.listVersion) return;
        this.errorMessage = 'Could not load workout sessions from the API.';
        this.isLoadingMore = false;
      }
    });
  }

  save(): void {
    if (this.isSaving) return;
    this.errorMessage = '';
    this.successMessage = '';

    if (!this.form.title.trim()) {
      this.errorMessage = 'Workout title is required.';
      return;
    }

    if (this.form.exercises.length === 0 || this.form.exercises.some((exercise) => !exercise.exerciseId)) {
      this.errorMessage = 'Add at least one exercise.';
      return;
    }

    if (this.form.exercises.some((exercise) => exercise.sets.length === 0 || exercise.sets.some((set) => !set.reps))) {
      this.errorMessage = 'Every exercise needs at least one set with reps.';
      return;
    }

    const payload = this.toPayload();
    this.isSaving = true;

    this.workoutSessionService.create(payload).subscribe({
      next: () => {
        this.successMessage = 'Workout session created.';
        this.isSaving = false;
        this.closeDialog();
        this.loadPageData();
      },
      error: () => {
        this.errorMessage = 'Could not create workout session. Check the athlete profile and exercises.';
        this.isSaving = false;
      }
    });
  }

  viewDetails(session: WorkoutSession): void {
    this.errorMessage = '';
    this.workoutSessionService.getById(session.id).subscribe({
      next: (details) => {
        this.selectedSession = details;
        if (!this.detailsDialog.nativeElement.open) this.detailsDialog.nativeElement.showModal();
      },
      error: () => {
        this.errorMessage = 'Could not load workout session details.';
      }
    });
  }

  delete(session: WorkoutSession): void {
    if (!confirm(this.preferences.translate('Delete {name}?', { name: session.title }))) {
      return;
    }

    this.workoutSessionService.delete(session.id).subscribe({
      next: () => {
        if (this.selectedSession?.id === session.id) {
          this.selectedSession = null;
        }

        this.loadPageData();
      },
      error: () => {
        this.errorMessage = 'Could not delete workout session.';
      }
    });
  }

  addExercise(): void {
    this.form.exercises.push(this.createExerciseForm());
    this.reorderExercises();
  }

  removeExercise(index: number): void {
    this.form.exercises.splice(index, 1);
    this.reorderExercises();
  }

  addSet(exercise: WorkoutExerciseForm): void {
    exercise.sets.push(this.createSetForm(exercise.sets.length + 1));
  }

  removeSet(exercise: WorkoutExerciseForm, setIndex: number): void {
    exercise.sets.splice(setIndex, 1);
    exercise.sets.forEach((set, index) => {
      set.setNumber = index + 1;
    });
  }

  resetForm(): void {
    this.form = this.createEmptyForm();
    this.ensureDefaultExerciseSelected();
  }

  openCreateDialog(): void {
    this.resetForm();
    this.errorMessage = '';
    this.successMessage = '';
    this.dialog.nativeElement.showModal();
  }

  closeDialog(): void {
    if (!this.isSaving) this.dialog.nativeElement.close();
  }

  onDialogClose(): void {
    this.resetForm();
    this.errorMessage = '';
  }

  onDialogCancel(event: Event): void {
    if (this.isSaving) event.preventDefault();
  }

  getExerciseName(exerciseId: string): string {
    return this.exercises.find((exercise) => exercise.id === exerciseId)?.name ?? this.preferences.translate('Select exercise');
  }

  private toPayload(): CreateWorkoutSessionRequest {
    return {
      title: this.form.title.trim(),
      sessionDate: new Date(this.form.sessionDate).toISOString(),
      durationMinutes: this.form.durationMinutes ?? undefined,
      notes: this.form.notes.trim() || undefined,
      exercises: this.form.exercises.map<CreateWorkoutExerciseRequest>((exercise, index) => ({
        exerciseId: exercise.exerciseId,
        orderIndex: index + 1,
        notes: exercise.notes.trim() || undefined,
        sets: exercise.sets.map<CreateWorkoutSetRequest>((set, setIndex) => ({
          setNumber: setIndex + 1,
          weight: set.weight ?? undefined,
          reps: set.reps ?? 0,
          resistanceNote: set.resistanceNote.trim() || undefined,
          rpe: set.rpe ?? undefined,
          isWarmup: set.isWarmup
        }))
      }))
    };
  }

  private createEmptyForm(): WorkoutSessionForm {
    return {
      title: 'Upper A',
      sessionDate: this.todayForDateInput(),
      durationMinutes: null,
      notes: '',
      exercises: [this.createExerciseForm()]
    };
  }

  private createExerciseForm(): WorkoutExerciseForm {
    return {
      exerciseId: this.exercises[0]?.id ?? '',
      notes: '',
      sets: [this.createSetForm(1)]
    };
  }

  private createSetForm(setNumber: number): WorkoutSetForm {
    return {
      setNumber,
      weight: null,
      reps: null,
      resistanceNote: '',
      rpe: null,
      isWarmup: false
    };
  }

  private ensureDefaultExerciseSelected(): void {
    if (this.exercises.length === 0) {
      return;
    }

    for (const exercise of this.form.exercises) {
      if (!exercise.exerciseId) {
        exercise.exerciseId = this.exercises[0].id;
      }
    }
  }

  private reorderExercises(): void {
    this.form.exercises = this.form.exercises.map((exercise) => ({
      ...exercise,
      sets: exercise.sets.map((set, index) => ({ ...set, setNumber: index + 1 }))
    }));
  }

  private todayForDateInput(): string {
    return new Date().toISOString().slice(0, 10);
  }
}
