import { Component, inject } from '@angular/core';
import { PreferencesService } from './core/preferences/preferences.service';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss'
})
export class AppComponent {
  readonly preferences = inject(PreferencesService);
}
