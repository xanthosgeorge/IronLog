import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';
import { BodyWeightPageComponent, browserDate } from './body-weight-page.component';
import { BodyWeightService } from './body-weight.service';

describe('Body weight recording', () => {
  const entry = { id: 'measurement', recordedOn: '2026-10-15', weightKg: 75.55 };
  let service: jasmine.SpyObj<BodyWeightService>;

  beforeEach(() => {
    service = jasmine.createSpyObj('BodyWeightService', ['getAll', 'create']);
    service.getAll.and.returnValue(of([]));
    service.create.and.returnValue(of(entry));
    TestBed.configureTestingModule({
      imports: [BodyWeightPageComponent],
      providers: [{ provide: BodyWeightService, useValue: service }]
    });
  });

  it('uses the local calendar date near midnight', () => {
    expect(browserDate(new Date(2026, 0, 2, 0, 1))).toBe('2026-01-02');
    expect(browserDate(new Date(2026, 0, 2, 23, 59))).toBe('2026-01-02');
  });

  it('resets to browser today whenever the popup is opened', () => {
    const fixture = TestBed.createComponent(BodyWeightPageComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;
    component.recordedOn = '2020-01-01';
    component.openDialog();
    expect(component.recordedOn).toBe(browserDate());
    expect(component.dialog.nativeElement.open).toBeTrue();
    component.closeDialog();
  });

  it('accepts a decimal comma and preserves the selected historical date', () => {
    const fixture = TestBed.createComponent(BodyWeightPageComponent);
    fixture.detectChanges();
    const component = fixture.componentInstance;
    component.recordedOn = entry.recordedOn;
    component.weight = '75,55';
    component.save();
    expect(service.create).toHaveBeenCalledOnceWith({ recordedOn: entry.recordedOn, weightKg: 75.55 });
    expect(service.getAll).toHaveBeenCalledTimes(2);
  });

  it('rejects invalid weights without sending a request', () => {
    const component = TestBed.createComponent(BodyWeightPageComponent).componentInstance;
    for (const weight of ['0', '-1', '1001', '75.555', 'abc']) {
      component.weight = weight;
      component.save();
      expect(component.formError).not.toBe('');
    }
    expect(service.create).not.toHaveBeenCalled();
  });

  it('keeps entered values when saving fails so the user can retry', () => {
    service.create.and.returnValue(throwError(() => new Error('offline')));
    const component = TestBed.createComponent(BodyWeightPageComponent).componentInstance;
    component.recordedOn = entry.recordedOn;
    component.weight = '75.55';
    component.save();
    expect(component.saving).toBeFalse();
    expect(component.formError).not.toBe('');
    expect(component.weight).toBe('75.55');
    expect(component.recordedOn).toBe(entry.recordedOn);
  });
});
