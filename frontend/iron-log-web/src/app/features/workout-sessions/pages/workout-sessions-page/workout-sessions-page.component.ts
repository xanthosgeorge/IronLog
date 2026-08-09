import { Component, OnInit } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Exercise } from '../../../exercises/models/exercise.model';
import { ExerciseService } from '../../../exercises/services/exercise.service';
import { environment } from '../../../../../environments/environment';
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
  imports: [DatePipe, DecimalPipe, FormsModule],
  templateUrl: './workout-sessions-page.component.html',
  styleUrl: './workout-sessions-page.component.scss'
})
export class WorkoutSessionsPageComponent implements OnInit {
  sessions: WorkoutSession[] = [];
  exercises: Exercise[] = [];
  selectedSession: WorkoutSession | null = null;
  form: WorkoutSessionForm = this.createEmptyForm();
  isLoading = false;
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
    this.isLoading = true;
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

    this.workoutSessionService.getAll().subscribe({
      next: (items) => {
        this.sessions = items;
        this.isLoading = false;
      },
      error: () => {
        this.errorMessage = 'Could not load workout sessions from the API.';
        this.isLoading = false;
      }
    });
  }

  save(): void {
    this.errorMessage = '';
    this.successMessage = '';

    if (!environment.currentAthleteId) {
      this.errorMessage = 'Athlete profile is not configured yet.';
      return;
    }

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
        this.resetForm();
        this.loadPageData();
      },
      error: () => {
        this.errorMessage = 'Could not create workout session. Check the athlete profile and exercises.';
        this.isSaving = false;
      }
    });
  }

  viewDetails(session: WorkoutSession): void {
    this.workoutSessionService.getById(session.id).subscribe({
      next: (details) => {
        this.selectedSession = details;
      },
      error: () => {
        this.errorMessage = 'Could not load workout session details.';
      }
    });
  }

  delete(session: WorkoutSession): void {
    if (!confirm(`Delete ${session.title}?`)) {
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

  getExerciseName(exerciseId: string): string {
    return this.exercises.find((exercise) => exercise.id === exerciseId)?.name ?? 'Select exercise';
  }

  private toPayload(): CreateWorkoutSessionRequest {
    return {
      userId: environment.currentAthleteId,
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
