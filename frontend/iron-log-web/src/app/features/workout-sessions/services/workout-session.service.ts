import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../../environments/environment';
import { CreateWorkoutSessionRequest, WorkoutSession } from '../models/workout-session.model';

@Injectable({ providedIn: 'root' })
export class WorkoutSessionService {
  private readonly url = `${environment.apiBaseUrl}/api/WorkoutSessions`;

  constructor(private readonly http: HttpClient) {}

  getAll(): Observable<WorkoutSession[]> {
    return this.http.get<WorkoutSession[]>(this.url);
  }

  getById(id: string): Observable<WorkoutSession> {
    return this.http.get<WorkoutSession>(`${this.url}/${id}`);
  }

  create(payload: CreateWorkoutSessionRequest): Observable<{ id: string }> {
    return this.http.post<{ id: string }>(this.url, payload);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
