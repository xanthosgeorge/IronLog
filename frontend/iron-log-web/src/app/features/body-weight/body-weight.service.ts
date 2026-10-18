import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { environment } from '../../../environments/environment';

export interface BodyWeightEntry { id: string; recordedOn: string; weightKg: number; }
export interface BodyWeightPayload { recordedOn: string; weightKg: number; }

@Injectable({ providedIn: 'root' })
export class BodyWeightService {
  private readonly http = inject(HttpClient);
  private readonly url = `${environment.apiBaseUrl}/api/BodyWeights`;
  getAll() { return this.http.get<BodyWeightEntry[]>(this.url); }
  create(payload: BodyWeightPayload) { return this.http.post<BodyWeightEntry>(this.url, payload); }
}
