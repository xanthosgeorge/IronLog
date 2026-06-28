export interface Exercise {
  id: string;
  muscleGroupId: string;
  muscleGroupName: string;
  name: string;
  equipmentType?: string;
  isActive: boolean;
}

export interface ExercisePayload {
  muscleGroupId: string;
  name: string;
  equipmentType?: string;
  isActive: boolean;
}
