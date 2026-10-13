import { Component, inject, signal } from '@angular/core';
import { AvatarService } from '../../core/preferences/avatar.service';
import { PreferencesService, themes } from '../../core/preferences/preferences.service';
import { TranslatePipe } from '../../core/preferences/translate.pipe';

@Component({
  selector: 'app-settings-page',
  imports: [TranslatePipe],
  templateUrl: './settings-page.component.html',
  styleUrl: './settings-page.component.scss'
})
export class SettingsPageComponent {
  readonly avatar = inject(AvatarService);
  readonly isUploading = signal(false);
  readonly avatarError = signal('');
  readonly preferences = inject(PreferencesService);
  readonly themes = [
    { id: 'red' as const, label: 'Red / Gray', ...themes.red },
    { id: 'blue' as const, label: 'Blue / Gray', ...themes.blue },
    { id: 'green' as const, label: 'Green / Gray', ...themes.green },
    { id: 'orange' as const, label: 'Orange / Gray', ...themes.orange },
    { id: 'fuchsia' as const, label: 'Fuchsia / Gray', ...themes.fuchsia },
    { id: 'turquoise' as const, label: 'Turquoise / Gray', ...themes.turquoise }
  ];

  async uploadPhoto(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!file || this.isUploading()) return;
    this.avatarError.set('');
    this.isUploading.set(true);
    try { await this.avatar.upload(file); }
    catch (error) { this.avatarError.set(error instanceof Error ? error.message : 'Could not save your photo in this browser.'); }
    finally { this.isUploading.set(false); }
  }

  removePhoto(): void {
    this.avatarError.set('');
    try { this.avatar.remove(); }
    catch (error) { this.avatarError.set(error instanceof Error ? error.message : 'Could not remove your photo.'); }
  }
}
