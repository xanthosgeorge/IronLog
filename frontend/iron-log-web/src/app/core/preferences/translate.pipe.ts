import { Pipe, PipeTransform, inject } from '@angular/core';
import { DatePipe, DecimalPipe, registerLocaleData } from '@angular/common';
import greekLocale from '@angular/common/locales/el';
import { PreferencesService } from './preferences.service';

registerLocaleData(greekLocale);

@Pipe({ name: 'translate', pure: false })
export class TranslatePipe implements PipeTransform {
  private readonly preferences = inject(PreferencesService);
  transform(value: string | null | undefined): string { return this.preferences.translate(value ?? ''); }
}

@Pipe({ name: 'date', pure: false })
export class LocalDatePipe implements PipeTransform {
  private readonly preferences = inject(PreferencesService);
  private readonly pipe = new DatePipe('en-US');
  transform(value: string | number | Date | null | undefined, format = 'mediumDate'): string | null {
    return this.pipe.transform(value, format, undefined, this.preferences.locale());
  }
}

@Pipe({ name: 'number', pure: false })
export class LocalNumberPipe implements PipeTransform {
  private readonly preferences = inject(PreferencesService);
  private readonly pipe = new DecimalPipe('en-US');
  transform(value: string | number | null | undefined, digits = '1.0-3'): string | null {
    return this.pipe.transform(value, digits, this.preferences.locale());
  }
}
