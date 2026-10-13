import { TestBed } from '@angular/core/testing';
import { SettingsPageComponent } from './settings-page.component';
import { AuthService } from '../../core/auth/auth.service';

describe('SettingsPageComponent', () => {
  beforeEach(async () => {
    localStorage.removeItem('ironlog.preferences');
    await TestBed.configureTestingModule({
      imports: [SettingsPageComponent],
      providers: [{ provide: AuthService, useValue: { currentUser: () => ({ id: 'settings-test', firstName: 'Test', lastName: 'User', email: 'test@example.invalid' }) } }]
    }).compileComponents();
  });
  afterEach(() => localStorage.removeItem('ironlog.preferences'));

  it('reports invalid uploads and enables choosing another file', async () => {
    const fixture = TestBed.createComponent(SettingsPageComponent);
    fixture.detectChanges();
    const input = fixture.nativeElement.querySelector('input[type="file"]') as HTMLInputElement;
    const files = new DataTransfer();
    files.items.add(new File(['not an image'], 'avatar.txt', { type: 'text/plain' }));
    input.files = files.files;
    await fixture.componentInstance.uploadPhoto({ target: input } as unknown as Event);
    fixture.detectChanges();
    expect(fixture.componentInstance.isUploading()).toBeFalse();
    expect(fixture.componentInstance.avatarError()).toBe('Choose a JPG, PNG or WebP image.');
    expect(input.value).toBe('');
    expect(fixture.nativeElement.querySelector('[role="alert"]')).toBeTruthy();
    fixture.destroy();
  });

  it('switches language and selects all themes through the visible controls', () => {
    const fixture = TestBed.createComponent(SettingsPageComponent);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    (element.querySelector('input[value="el"]') as HTMLInputElement).click();
    fixture.detectChanges();
    expect(element.querySelector('h1')?.textContent).toBe('Ρυθμίσεις');
    for (const theme of ['blue', 'green', 'orange', 'fuchsia', 'turquoise', 'red'] as const) {
      (element.querySelector(`input[value="${theme}"]`) as HTMLInputElement).click();
      fixture.detectChanges();
      expect(fixture.componentInstance.preferences.theme()).toBe(theme);
      expect(element.querySelectorAll('.selected').length).toBe(1);
    }
    (element.querySelector('input[value="en"]') as HTMLInputElement).click();
    fixture.detectChanges();
    expect(element.querySelector('h1')?.textContent).toBe('Settings');
    fixture.destroy();
  });
});
