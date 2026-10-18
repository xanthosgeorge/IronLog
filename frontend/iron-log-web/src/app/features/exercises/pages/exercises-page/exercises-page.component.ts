import { PreferencesService } from '../../../../core/preferences/preferences.service';
import { TranslatePipe } from '../../../../core/preferences/translate.pipe';
import { Component, ElementRef, OnInit, ViewChild, inject } from '@angular/core';

import { FormsModule } from '@angular/forms';
import { Observable } from 'rxjs';
import { Exercise, ExercisePayload } from '../../models/exercise.model';
import { MuscleGroup } from '../../../muscle-groups/models/muscle-group.model';
import { ExerciseService } from '../../services/exercise.service';
import { MuscleGroupService } from '../../../muscle-groups/services/muscle-group.service';

@Component({
  selector: 'app-exercises-page',
  imports: [TranslatePipe, FormsModule],
  templateUrl: './exercises-page.component.html',
  styleUrl: './exercises-page.component.scss'
})
export class ExercisesPageComponent implements OnInit {
  @ViewChild('exerciseDialog', { static: true }) dialog!: ElementRef<HTMLDialogElement>;
  readonly preferences = inject(PreferencesService);
  exercises: Exercise[] = [];
  muscleGroups: MuscleGroup[] = [];
  form: ExercisePayload = this.createEmptyForm();
  editingId: string | null = null;
  isLoading = false;
  isSaving = false;
  errorMessage = '';
  searchName = '';
  equipmentFilter: string | null = null;
  muscleGroupFilter = '';

  get equipmentOptions(): string[] {
    const values = new Map<string, string>();
    for (const exercise of this.exercises) {
      const value = exercise.equipmentType?.trim() ?? '';
      if (!values.has(this.normalize(value))) values.set(this.normalize(value), value);
    }
    return [...values.values()].sort((a, b) => a.localeCompare(b, this.preferences.locale()));
  }

  get filteredExercises(): Exercise[] {
    const name = this.normalize(this.searchName);
    return this.exercises.filter(exercise =>
      (!name || this.normalize(exercise.name).includes(name)) &&
      (this.equipmentFilter === null || this.normalize(exercise.equipmentType ?? '') === this.normalize(this.equipmentFilter)) &&
      (!this.muscleGroupFilter || exercise.muscleGroupId === this.muscleGroupFilter));
  }

  get hasFilters(): boolean {
    return !!this.searchName || this.equipmentFilter !== null || !!this.muscleGroupFilter;
  }

  clearFilters(): void {
    this.searchName = '';
    this.equipmentFilter = null;
    this.muscleGroupFilter = '';
  }

  private normalize(value: string): string {
    return value.trim().toLocaleLowerCase(this.preferences.locale()).normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '').replace(/ς/g, 'σ');
  }

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
    if (this.isSaving) return;
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
        this.isSaving = false;
        this.closeDialog();
        this.loadPageData();
      },
      error: () => {
        this.errorMessage = 'Could not save the exercise.';
        this.isSaving = false;
      }
    });
  }

  edit(item: Exercise): void {
    this.errorMessage = '';
    this.editingId = item.id;
    this.form = {
      muscleGroupId: item.muscleGroupId,
      name: item.name,
      equipmentType: item.equipmentType ?? '',
      isActive: item.isActive
    };
    this.dialog.nativeElement.showModal();
  }

  openCreateDialog(): void {
    this.resetForm();
    this.errorMessage = '';
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

  delete(item: Exercise): void {
    if (!confirm(this.preferences.translate('Delete {name}?', { name: item.name }))) {
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
      || this.preferences.translate('Unassigned');
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
