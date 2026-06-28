import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Exercise, ExercisePayload } from '../models/exercise.model';

@Injectable({ providedIn: 'root' })
export class ExerciseService {
  private readonly url = `${environment.apiBaseUrl}/api/Exercises`;

  constructor(private readonly http: HttpClient) {}

  getAll(): Observable<Exercise[]> {
    return this.http.get<Exercise[]>(this.url);
  }

  create(payload: ExercisePayload): Observable<Exercise> {
    return this.http.post<Exercise>(this.url, payload);
  }

  update(id: string, payload: ExercisePayload): Observable<void> {
    return this.http.put<void>(`${this.url}/${id}`, payload);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
