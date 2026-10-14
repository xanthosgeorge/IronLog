import { DOCUMENT } from '@angular/common';
import { Injectable, computed, inject, signal } from '@angular/core';
import { greek } from './translations';

export type Language = 'en' | 'el';
export type Theme = 'red' | 'blue' | 'green' | 'orange' | 'fuchsia' | 'turquoise';
export const themes = {
  red: { color: '#e53935', soft: '#ff8581', dark: '#a90f0f', rgb: '229, 57, 53' },
  blue: { color: '#287bdc', soft: '#80baff', dark: '#14519b', rgb: '40, 123, 220' },
  green: { color: '#23875e', soft: '#71d5a8', dark: '#156143', rgb: '35, 135, 94' },
  orange: { color: '#c65b16', soft: '#ffb075', dark: '#8f3c0a', rgb: '198, 91, 22' },
  fuchsia: { color: '#c62d91', soft: '#ff8dd4', dark: '#8d1462', rgb: '198, 45, 145' },
  turquoise: { color: '#0d9488', soft: '#5eead4', dark: '#0f766e', rgb: '13, 148, 136' }
};

@Injectable({ providedIn: 'root' })
export class PreferencesService {
  private readonly document = inject(DOCUMENT);
  private readonly state = signal<{ language: Language; theme: Theme }>(this.read());
  readonly language = computed(() => this.state().language);
  readonly theme = computed(() => this.state().theme);
  readonly locale = computed(() => this.language() === 'el' ? 'el-GR' : 'en-US');
  readonly palette = computed(() => themes[this.theme()]);

  constructor() { this.apply(); }

  setLanguage(language: Language): void { this.update({ language }); }
  setTheme(theme: Theme): void { this.update({ theme }); }

  translate(text: string, params: Record<string, string | number> = {}): string {
    const translated = this.language() === 'el' ? greek[text] ?? text : text;
    return translated.replace(/\{(\w+)\}/g, (match, key: string) => String(params[key] ?? match));
  }

  private update(change: Partial<{ language: Language; theme: Theme }>): void {
    this.state.update(current => ({ ...current, ...change }));
    this.apply();
    try { this.document.defaultView?.localStorage.setItem('ironlog.preferences', JSON.stringify(this.state())); } catch { /* Preferences remain usable when storage is unavailable. */ }
  }

  private apply(): void {
    const root = this.document.documentElement;
    root.lang = this.language();
    root.dataset['theme'] = this.theme();
    const palette = this.palette();
    root.style.setProperty('--accent', palette.color);
    root.style.setProperty('--accent-soft', palette.soft);
    root.style.setProperty('--accent-dark', palette.dark);
    root.style.setProperty('--accent-rgb', palette.rgb);
    const favicon = this.document.querySelector<HTMLLinkElement>('link[rel="icon"]');
    if (favicon) {
      favicon.type = 'image/svg+xml';
      favicon.href = `favicon-${this.theme()}.svg`;
    }
  }

  private read(): { language: Language; theme: Theme } {
    try {
      const saved = JSON.parse(this.document.defaultView?.localStorage.getItem('ironlog.preferences') ?? '{}');
      return { language: saved?.language === 'el' ? 'el' : 'en', theme: ['red', 'blue', 'green', 'orange', 'fuchsia', 'turquoise'].includes(saved?.theme) ? saved.theme : 'red' };
    } catch { return { language: 'en', theme: 'red' }; }
  }
}
