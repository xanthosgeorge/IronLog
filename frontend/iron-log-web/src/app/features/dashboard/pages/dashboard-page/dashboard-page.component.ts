import { Component } from '@angular/core';


@Component({
  selector: 'app-dashboard-page',
  imports: [],
  templateUrl: './dashboard-page.component.html',
  styleUrl: './dashboard-page.component.scss'
})
export class DashboardPageComponent {
  metrics = [
    { label: 'Total Workouts', value: '48', detail: 'This month 12', icon: 'B' },
    { label: 'Total Volume', value: '24,580 kg', detail: 'This month +18%', icon: 'V' },
    { label: 'Current Streak', value: '7', detail: 'Days', icon: 'S' },
    { label: 'Body Weight', value: '94.2 kg', detail: '-1.3 kg this month', icon: 'W' }
  ];

  recentWorkouts = [
    { name: 'Upper A', date: 'Aug 12, 2024', duration: '1h 10m', volume: '18,450 kg' },
    { name: 'Lower A', date: 'Aug 9, 2024', duration: '1h 05m', volume: '21,230 kg' },
    { name: 'Push', date: 'Aug 6, 2024', duration: '55m', volume: '15,680 kg' },
    { name: 'Pull', date: 'Aug 3, 2024', duration: '1h 00m', volume: '17,950 kg' }
  ];

  performance = [
    { name: 'Bench Press', group: 'Chest', metric: '1RM Estimate', value: '90 kg', change: '+5%' },
    { name: 'Pull Ups', group: 'Back', metric: 'Max Reps', value: '12', change: '+20%' },
    { name: 'Squat', group: 'Legs', metric: '1RM Estimate', value: '120 kg', change: '+3%' }
  ];
}
