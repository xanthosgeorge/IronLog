import { Component, DestroyRef, ElementRef, OnDestroy, OnInit, ViewChild, effect, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Chart, CategoryScale, LinearScale, LineController, LineElement, PointElement, Tooltip, Filler } from 'chart.js';
import { PreferencesService } from '../../core/preferences/preferences.service';
import { TranslatePipe } from '../../core/preferences/translate.pipe';
import { BodyWeightEntry, BodyWeightService } from './body-weight.service';

Chart.register(CategoryScale, LinearScale, LineController, LineElement, PointElement, Tooltip, Filler);

export function browserDate(date = new Date()): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

@Component({
  selector: 'app-body-weight-page',
  imports: [FormsModule, TranslatePipe],
  templateUrl: './body-weight-page.component.html',
  styleUrl: './body-weight-page.component.scss'
})
export class BodyWeightPageComponent implements OnInit, OnDestroy {
  @ViewChild('weightDialog', { static: true }) dialog!: ElementRef<HTMLDialogElement>;
  @ViewChild('weightCanvas', { static: true }) canvas!: ElementRef<HTMLCanvasElement>;
  readonly preferences = inject(PreferencesService);
  private readonly service = inject(BodyWeightService);
  private readonly destroyRef = inject(DestroyRef);
  entries: BodyWeightEntry[] = [];
  recordedOn = browserDate();
  weight = '';
  loading = true;
  saving = false;
  error = '';
  formError = '';
  private chart?: Chart<'line', number[], string>;

  constructor() {
    effect(() => { this.preferences.theme(); this.preferences.language(); this.renderChart(); });
  }
  ngOnInit(): void { this.load(); }
  ngOnDestroy(): void { this.chart?.destroy(); }

  load(): void {
    this.loading = true;
    this.error = '';
    this.service.getAll().pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
      next: entries => { this.entries = entries; this.loading = false; this.renderChart(); },
      error: () => { this.loading = false; this.error = 'Could not load body weight history.'; }
    });
  }
  openDialog(): void {
    this.recordedOn = browserDate();
    this.weight = '';
    this.formError = '';
    this.dialog.nativeElement.showModal();
  }
  closeDialog(): void { if (!this.saving) this.dialog.nativeElement.close(); }
  onCancel(event: Event): void { if (this.saving) event.preventDefault(); }
  save(): void {
    if (this.saving) return;
    this.formError = '';
    if (!/^\d{4}-\d{2}-\d{2}$/.test(this.recordedOn)) { this.formError = 'Choose a valid date.'; return; }
    const text = this.weight.trim().replace(',', '.');
    const weightKg = Number(text);
    if (!/^\d+(\.\d{1,2})?$/.test(text) || weightKg <= 0 || weightKg > 1000) {
      this.formError = 'Enter a weight between 0.01 and 1000 kg with up to two decimal places.'; return;
    }
    this.saving = true;
    this.service.create({ recordedOn: this.recordedOn, weightKg }).pipe(takeUntilDestroyed(this.destroyRef)).subscribe({
      next: () => { this.saving = false; this.closeDialog(); this.load(); },
      error: () => { this.saving = false; this.formError = 'Could not save body weight. Please try again.'; }
    });
  }

  private renderChart(): void {
    if (!this.canvas) return;
    this.chart?.destroy();
    this.chart = undefined;
    if (!this.entries.length) return;
    const locale = this.preferences.locale();
    this.chart = new Chart(this.canvas.nativeElement, {
      type: 'line',
      data: {
        labels: this.entries.map(e => new Date(`${e.recordedOn}T12:00:00`).toLocaleDateString(locale)),
        datasets: [{
          label: this.preferences.translate('Body weight'), data: this.entries.map(e => e.weightKg),
          borderColor: this.preferences.palette().soft, backgroundColor: `rgba(${this.preferences.palette().rgb}, 0.12)`,
          pointBackgroundColor: this.preferences.palette().soft, pointRadius: 5, pointHoverRadius: 7,
          borderWidth: 3, fill: true, tension: 0
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false, animation: false,
        plugins: { tooltip: { callbacks: { label: item => `${item.parsed.y?.toLocaleString(locale)} kg` } } },
        scales: {
          x: { grid: { display: false }, ticks: { color: '#a5acb8', maxTicksLimit: 8, maxRotation: 0 } },
          y: { title: { display: true, text: 'kg', color: '#a5acb8' }, ticks: { color: '#a5acb8' }, grid: { color: 'rgba(255,255,255,0.07)' } }
        }
      }
    });
  }
}
