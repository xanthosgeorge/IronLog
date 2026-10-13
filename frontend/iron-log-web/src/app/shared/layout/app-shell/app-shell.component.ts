import { TranslatePipe } from '../../../core/preferences/translate.pipe';
import { Component, inject } from '@angular/core';
import { AvatarService } from '../../../core/preferences/avatar.service';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../../../core/auth/auth.service';

@Component({
  selector: 'app-app-shell',
  imports: [TranslatePipe, RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './app-shell.component.html',
  styleUrl: './app-shell.component.scss'
})
export class AppShellComponent {
  readonly avatar = inject(AvatarService);
  constructor(readonly auth: AuthService) {}
}
