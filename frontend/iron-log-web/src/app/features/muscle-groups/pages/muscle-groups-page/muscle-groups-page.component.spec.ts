import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MuscleGroupsPageComponent } from './muscle-groups-page.component';
import { of, Subject } from 'rxjs';
import { MuscleGroupService } from '../../services/muscle-group.service';
import { MuscleGroup } from '../../models/muscle-group.model';

describe('MuscleGroupsPageComponent', () => {
  let component: MuscleGroupsPageComponent;
  let fixture: ComponentFixture<MuscleGroupsPageComponent>;
  let service: jasmine.SpyObj<MuscleGroupService>;
  let response: Subject<unknown>;
  const group: MuscleGroup = { id: 'chest', name: 'Chest', description: 'Chest muscles' };

  beforeEach(async () => {
    service = jasmine.createSpyObj('MuscleGroupService', ['getAll', 'create', 'update']);
    response = new Subject();
    service.getAll.and.returnValue(of([group]));
    service.create.and.returnValue(response as Subject<MuscleGroup>);
    service.update.and.returnValue(response as Subject<void>);
    await TestBed.configureTestingModule({
      imports: [MuscleGroupsPageComponent],
      providers: [{ provide: MuscleGroupService, useValue: service }]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MuscleGroupsPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => fixture.destroy());

  it('opens a blank form from the Create button and focuses the name', () => {
    expect(component.dialog.nativeElement.open).toBeFalse();
    (fixture.nativeElement.querySelector('.page-header button') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(component.form.name).toBe('');
    expect(document.activeElement).toBe(component.dialog.nativeElement.querySelector('input[name="name"]'));
  });

  it('waits for successful creation before closing and refreshing', () => {
    component.openCreateDialog();
    component.form.name = 'New group';
    component.save();
    component.save();
    expect(service.create).toHaveBeenCalledTimes(1);
    expect(component.dialog.nativeElement.open).toBeTrue();
    response.next(group);
    expect(component.dialog.nativeElement.open).toBeFalse();
    expect(component.isSaving).toBeFalse();
    expect(service.getAll).toHaveBeenCalledTimes(2);
  });

  it('keeps the form and error visible after a failed save', () => {
    component.openCreateDialog();
    component.form.name = 'New group';
    component.save();
    response.error(new Error('offline'));
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(component.form.name).toBe('New group');
    expect(component.errorMessage).toBeTruthy();
    expect(component.isSaving).toBeFalse();
  });

  it('edits an existing group in the dialog', () => {
    component.edit(group);
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect(component.form).toEqual({ name: group.name, description: group.description });
    component.save();
    expect(service.update).toHaveBeenCalledWith(group.id, jasmine.objectContaining({ name: group.name }));
    response.next(undefined);
    expect(component.dialog.nativeElement.open).toBeFalse();
  });

  it('supports cancellation and prevents dismissal during saving', () => {
    component.openCreateDialog();
    component.form.name = 'Unsaved';
    component.closeDialog();
    expect(component.dialog.nativeElement.open).toBeFalse();
    component.openCreateDialog();
    expect(component.form.name).toBe('');
    component.form.name = 'New group';
    component.save();
    fixture.detectChanges();
    component.closeDialog();
    const event = new Event('cancel', { cancelable: true });
    component.dialog.nativeElement.dispatchEvent(event);
    expect(event.defaultPrevented).toBeTrue();
    expect(component.dialog.nativeElement.open).toBeTrue();
    expect((component.dialog.nativeElement.querySelector('fieldset') as HTMLFieldSetElement).disabled).toBeTrue();
  });

  it('does not close or submit when the name is missing', () => {
    component.openCreateDialog();
    component.save();
    expect(service.create).not.toHaveBeenCalled();
    expect(component.dialog.nativeElement.open).toBeTrue();
  });
});
