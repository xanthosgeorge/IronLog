export interface MuscleGroup {
  id: string;
  name: string;
  description?: string;
}

export type MuscleGroupPayload = Omit<MuscleGroup, 'id'>;
