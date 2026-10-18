import { Routes } from '@angular/router';
import { AppShellComponent } from './shared/layout/app-shell/app-shell.component';
import { authGuard } from './core/auth/auth.guard';
import { LoginPageComponent } from './features/auth/pages/login-page/login-page.component';

export const routes: Routes = [
  { path: 'login', component: LoginPageComponent },
  {
    path: '',
    component: AppShellComponent,
    canActivateChild: [authGuard],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      {
        path: 'dashboard',
        loadChildren: () => import('./features/dashboard/dashboard.routes').then((m) => m.dashboardRoutes)
      },
      {
        path: 'muscle-groups',
        loadChildren: () => import('./features/muscle-groups/muscle-groups.routes').then((m) => m.muscleGroupsRoutes)
      },
      {
        path: 'exercises',
        loadChildren: () => import('./features/exercises/exercises.routes').then((m) => m.exercisesRoutes)
      },
      {
        path: 'workout-sessions',
        loadChildren: () => import('./features/workout-sessions/workout-sessions.routes').then((m) => m.workoutSessionsRoutes)
      },
      { path: 'progress', redirectTo: 'dashboard' },
      { path: 'body-weight', loadComponent: () => import('./features/body-weight/body-weight-page.component').then(m => m.BodyWeightPageComponent) },
      { path: 'analytics', redirectTo: 'dashboard' },
      { path: 'settings', loadComponent: () => import('./features/settings/settings-page.component').then(m => m.SettingsPageComponent) }
    ]
  },
  { path: '**', redirectTo: 'dashboard' }
];
