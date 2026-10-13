import { PreferencesService } from '../../../../core/preferences/preferences.service';
import { TranslatePipe } from '../../../../core/preferences/translate.pipe';
import { Component, ElementRef, OnInit, ViewChild, inject } from '@angular/core';

import { FormsModule } from '@angular/forms';
import { Observable } from 'rxjs';
import { MuscleGroup, MuscleGroupPayload } from '../../models/muscle-group.model';
import { MuscleGroupService } from '../../services/muscle-group.service';

@Component({
  selector: 'app-muscle-groups-page',
  imports: [TranslatePipe, FormsModule],
  templateUrl: './muscle-groups-page.component.html',
  styleUrl: './muscle-groups-page.component.scss'
})
export class MuscleGroupsPageComponent implements OnInit {
  @ViewChild('muscleGroupDialog', { static: true }) dialog!: ElementRef<HTMLDialogElement>;
  readonly preferences = inject(PreferencesService);
  muscleGroups: MuscleGroup[] = [];
  form: MuscleGroupPayload = this.createEmptyForm();
  editingId: string | null = null;
  isLoading = false;
  isSaving = false;
  errorMessage = '';

  constructor(private readonly muscleGroupService: MuscleGroupService) {}

  ngOnInit(): void {
    this.loadMuscleGroups();
  }

  loadMuscleGroups(): void {
    this.isLoading = true;
    this.errorMessage = '';

    this.muscleGroupService.getAll().subscribe({
      next: (items) => {
        this.muscleGroups = items;
        this.isLoading = false;
      },
      error: () => {
        this.errorMessage = 'Could not load muscle groups from the API.';
        this.isLoading = false;
      }
    });
  }

  save(): void {
    if (this.isSaving) return;
    if (!this.form.name.trim()) {
      this.errorMessage = 'Name is required.';
      return;
    }

    const payload: MuscleGroupPayload = {
      name: this.form.name.trim(),
      description: this.form.description?.trim() || undefined
    };

    this.isSaving = true;
    this.errorMessage = '';

    const request: Observable<unknown> = this.editingId
      ? this.muscleGroupService.update(this.editingId, payload)
      : this.muscleGroupService.create(payload);

    request.subscribe({
      next: () => {
        this.isSaving = false;
        this.closeDialog();
        this.loadMuscleGroups();
      },
      error: () => {
        this.errorMessage = 'Could not save the muscle group.';
        this.isSaving = false;
      }
    });
  }

  edit(item: MuscleGroup): void {
    this.errorMessage = '';
    this.editingId = item.id;
    this.form = {
      name: item.name,
      description: item.description ?? ''
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

  delete(item: MuscleGroup): void {
    if (!confirm(this.preferences.translate('Delete {name}?', { name: item.name }))) {
      return;
    }

    this.muscleGroupService.delete(item.id).subscribe({
      next: () => this.loadMuscleGroups(),
      error: () => {
        this.errorMessage = 'Could not delete the muscle group.';
      }
    });
  }

  resetForm(): void {
    this.editingId = null;
    this.form = this.createEmptyForm();
  }

  private createEmptyForm(): MuscleGroupPayload {
    return {
      name: '',
      description: ''
    };
  }
}
