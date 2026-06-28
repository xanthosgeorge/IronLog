import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { MuscleGroup, MuscleGroupPayload } from '../models/muscle-group.model';

@Injectable({ providedIn: 'root' })
export class MuscleGroupService {
  private readonly url = `${environment.apiBaseUrl}/api/MuscleGroups`;

  constructor(private readonly http: HttpClient) {}

  getAll(): Observable<MuscleGroup[]> {
    return this.http.get<MuscleGroup[]>(this.url);
  }

  create(payload: MuscleGroupPayload): Observable<MuscleGroup> {
    return this.http.post<MuscleGroup>(this.url, payload);
  }

  update(id: string, payload: MuscleGroupPayload): Observable<void> {
    return this.http.put<void>(`${this.url}/${id}`, payload);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
