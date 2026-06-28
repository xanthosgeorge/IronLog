import { Routes } from '@angular/router';
import { AppShellComponent } from './shared/layout/app-shell/app-shell.component';
import { DashboardPageComponent } from './features/dashboard/pages/dashboard-page/dashboard-page.component';
import { MuscleGroupsPageComponent } from './features/muscle-groups/pages/muscle-groups-page/muscle-groups-page.component';
import { ExercisesPageComponent } from './features/exercises/pages/exercises-page/exercises-page.component';

export const routes: Routes = [
  {
    path: '',
    component: AppShellComponent,
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', component: DashboardPageComponent },
      { path: 'muscle-groups', component: MuscleGroupsPageComponent },
      { path: 'exercises', component: ExercisesPageComponent },
      { path: 'workout-sessions', redirectTo: 'dashboard' },
      { path: 'progress', redirectTo: 'dashboard' },
      { path: 'analytics', redirectTo: 'dashboard' },
      { path: 'settings', redirectTo: 'dashboard' }
    ]
  },
  { path: '**', redirectTo: 'dashboard' }
];
