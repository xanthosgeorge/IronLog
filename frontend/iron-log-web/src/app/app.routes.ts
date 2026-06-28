import { Routes } from '@angular/router';
import { AppShellComponent } from './shared/layout/app-shell/app-shell.component';

export const routes: Routes = [
  {
    path: '',
    component: AppShellComponent,
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
      { path: 'workout-sessions', redirectTo: 'dashboard' },
      { path: 'progress', redirectTo: 'dashboard' },
      { path: 'analytics', redirectTo: 'dashboard' },
      { path: 'settings', redirectTo: 'dashboard' }
    ]
  },
  { path: '**', redirectTo: 'dashboard' }
];
