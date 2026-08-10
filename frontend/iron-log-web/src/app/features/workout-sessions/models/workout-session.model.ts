export interface WorkoutSet {
  id: string;
  setNumber: number;
  weight?: number;
  reps: number;
  resistanceNote?: string;
  rpe?: number;
  isWarmup: boolean;
}

export interface WorkoutExercise {
  id: string;
  exerciseId: string;
  exerciseName: string;
  orderIndex: number;
  notes?: string;
  sets: WorkoutSet[];
}

export interface WorkoutSession {
  id: string;
  title: string;
  sessionDate: string;
  durationMinutes?: number;
  notes?: string;
  totalVolume?: number;
  exercises: WorkoutExercise[];
}

export interface CreateWorkoutSetRequest {
  setNumber: number;
  weight?: number;
  reps: number;
  resistanceNote?: string;
  rpe?: number;
  isWarmup: boolean;
}

export interface CreateWorkoutExerciseRequest {
  exerciseId: string;
  orderIndex: number;
  notes?: string;
  sets: CreateWorkoutSetRequest[];
}

export interface CreateWorkoutSessionRequest {
  title: string;
  sessionDate: string;
  durationMinutes?: number;
  notes?: string;
  exercises: CreateWorkoutExerciseRequest[];
}
