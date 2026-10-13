import { TestBed } from '@angular/core/testing';
import { PreferencesService } from './preferences.service';
import { LocalDatePipe, LocalNumberPipe, TranslatePipe } from './translate.pipe';

describe('PreferencesService', () => {
  beforeEach(() => {
    localStorage.removeItem('ironlog.preferences');
    TestBed.configureTestingModule({});
  });
  afterEach(() => localStorage.removeItem('ironlog.preferences'));

  it('defaults to English and red without changing the gray background', () => {
    const preferences = TestBed.inject(PreferencesService);
    expect(preferences.language()).toBe('en');
    expect(preferences.theme()).toBe('red');
    expect(document.documentElement.style.getPropertyValue('--accent')).toBe('#e53935');
    expect(document.documentElement.lang).toBe('en');
  });

  it('restores stored language and theme on initialization', () => {
    localStorage.setItem('ironlog.preferences', JSON.stringify({ language: 'el', theme: 'blue' }));
    const preferences = TestBed.inject(PreferencesService);
    expect(preferences.locale()).toBe('el-GR');
    expect(preferences.theme()).toBe('blue');
    expect(document.documentElement.lang).toBe('el');
    expect(document.documentElement.style.getPropertyValue('--accent')).toBe('#287bdc');
  });

  it('persists both settings when either one changes', () => {
    const preferences = TestBed.inject(PreferencesService);
    preferences.setLanguage('el');
    preferences.setTheme('green');
    expect(JSON.parse(localStorage.getItem('ironlog.preferences')!)).toEqual({ language: 'el', theme: 'green' });
    expect(document.documentElement.style.getPropertyValue('--accent')).toBe('#23875e');
  });

  it('falls back safely for corrupt saved preferences', () => {
    localStorage.setItem('ironlog.preferences', 'not json');
    const preferences = TestBed.inject(PreferencesService);
    expect(preferences.language()).toBe('en');
    expect(preferences.theme()).toBe('red');
  });

  it('rejects unsupported saved language and theme', () => {
    localStorage.setItem('ironlog.preferences', JSON.stringify({ language: 'unknown', theme: 'unknown' }));
    const preferences = TestBed.inject(PreferencesService);
    expect(preferences.language()).toBe('en');
    expect(preferences.theme()).toBe('red');
  });

  it('updates translated labels, dates and numbers when language changes', () => {
    const preferences = TestBed.inject(PreferencesService);
    const pipes = TestBed.runInInjectionContext(() => ({ text: new TranslatePipe(), date: new LocalDatePipe(), number: new LocalNumberPipe() }));
    expect(pipes.text.transform('Settings')).toBe('Settings');
    expect(pipes.number.transform(57.5)).toBe('57.5');
    const englishDate = pipes.date.transform('2026-10-05', 'fullDate');
    preferences.setLanguage('el');
    expect(pipes.text.transform('Settings')).toBe('Ρυθμίσεις');
    expect(pipes.number.transform(57.5)).toBe('57,5');
    expect(pipes.date.transform('2026-10-05', 'fullDate')).not.toBe(englishDate);
    expect(preferences.translate('Delete {name}?', { name: 'My exercise' })).toContain('My exercise');
    expect(preferences.translate('Custom name')).toBe('Custom name');
  });
});
