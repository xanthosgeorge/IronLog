import { Component, OnInit } from '@angular/core';
import { NgFor, NgIf } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Observable } from 'rxjs';
import { Exercise, ExercisePayload } from '../../models/exercise.model';
import { MuscleGroup } from '../../../muscle-groups/models/muscle-group.model';
import { ExerciseService } from '../../services/exercise.service';
import { MuscleGroupService } from '../../../muscle-groups/services/muscle-group.service';

@Component({
  selector: 'app-exercises-page',
  imports: [FormsModule, NgFor, NgIf],
  templateUrl: './exercises-page.component.html',
  styleUrl: './exercises-page.component.scss'
})
export class ExercisesPageComponent implements OnInit {
  exercises: Exercise[] = [];
  muscleGroups: MuscleGroup[] = [];
  form: ExercisePayload = this.createEmptyForm();
  editingId: string | null = null;
  isLoading = false;
  isSaving = false;
  errorMessage = '';

  constructor(
    private readonly exerciseService: ExerciseService,
    private readonly muscleGroupService: MuscleGroupService
  ) {}

  ngOnInit(): void {
    this.loadPageData();
  }

  loadPageData(): void {
    this.isLoading = true;
    this.errorMessage = '';

    this.muscleGroupService.getAll().subscribe({
      next: (groups) => {
        this.muscleGroups = groups;
        if (!this.form.muscleGroupId && groups.length > 0) {
          this.form.muscleGroupId = groups[0].id;
        }
      },
      error: () => {
        this.errorMessage = 'Could not load muscle groups.';
      }
    });

    this.exerciseService.getAll().subscribe({
      next: (items) => {
        this.exercises = items;
        this.isLoading = false;
      },
      error: () => {
        this.errorMessage = 'Could not load exercises from the API.';
        this.isLoading = false;
      }
    });
  }

  save(): void {
    if (!this.form.name.trim() || !this.form.muscleGroupId) {
      this.errorMessage = 'Exercise name and muscle group are required.';
      return;
    }

    const payload: ExercisePayload = {
      muscleGroupId: this.form.muscleGroupId,
      name: this.form.name.trim(),
      equipmentType: this.form.equipmentType?.trim() || undefined,
      isActive: this.form.isActive
    };

    this.isSaving = true;
    this.errorMessage = '';

    const request: Observable<unknown> = this.editingId
      ? this.exerciseService.update(this.editingId, payload)
      : this.exerciseService.create(payload);

    request.subscribe({
      next: () => {
        this.resetForm();
        this.isSaving = false;
        this.loadPageData();
      },
      error: () => {
        this.errorMessage = 'Could not save the exercise.';
        this.isSaving = false;
      }
    });
  }

  edit(item: Exercise): void {
    this.editingId = item.id;
    this.form = {
      muscleGroupId: item.muscleGroupId,
      name: item.name,
      equipmentType: item.equipmentType ?? '',
      isActive: item.isActive
    };
  }

  delete(item: Exercise): void {
    if (!confirm(`Delete ${item.name}?`)) {
      return;
    }

    this.exerciseService.delete(item.id).subscribe({
      next: () => this.loadPageData(),
      error: () => {
        this.errorMessage = 'Could not delete the exercise.';
      }
    });
  }

  resetForm(): void {
    const defaultMuscleGroupId = this.muscleGroups[0]?.id ?? '';
    this.editingId = null;
    this.form = this.createEmptyForm(defaultMuscleGroupId);
  }

  getMuscleGroupName(exercise: Exercise): string {
    return exercise.muscleGroupName
      || this.muscleGroups.find((group) => group.id === exercise.muscleGroupId)?.name
      || 'Unassigned';
  }

  private createEmptyForm(muscleGroupId = ''): ExercisePayload {
    return {
      muscleGroupId,
      name: '',
      equipmentType: '',
      isActive: true
    };
  }
}
