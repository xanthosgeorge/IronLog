import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MuscleGroupsPageComponent } from './muscle-groups-page.component';

describe('MuscleGroupsPageComponent', () => {
  let component: MuscleGroupsPageComponent;
  let fixture: ComponentFixture<MuscleGroupsPageComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MuscleGroupsPageComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MuscleGroupsPageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
