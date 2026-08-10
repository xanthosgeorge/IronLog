import { HttpClient } from '@angular/common/http';
import { Injectable, computed, signal } from '@angular/core';
import { tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthResponse, AuthenticatedUser, LoginRequest, RegisterRequest } from './auth.models';

interface StoredSession extends AuthResponse {}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly storageKey = 'ironlog.session';
  private readonly url = `${environment.apiBaseUrl}/api/Auth`;
  private readonly session = signal<StoredSession | null>(this.readStoredSession());

  readonly currentUser = computed<AuthenticatedUser | null>(() => this.session()?.user ?? null);
  readonly isAuthenticated = computed(() => this.session() !== null && !this.isExpired(this.session()!));

  constructor(private readonly http: HttpClient) {}

  login(request: LoginRequest) {
    return this.http.post<AuthResponse>(`${this.url}/login`, request).pipe(tap((response) => this.storeSession(response)));
  }

  register(request: RegisterRequest) {
    return this.http.post<AuthResponse>(`${this.url}/register`, request).pipe(tap((response) => this.storeSession(response)));
  }

  token(): string | null {
    return this.isAuthenticated() ? this.session()?.accessToken ?? null : null;
  }

  logout(): void {
    this.session.set(null);
    localStorage.removeItem(this.storageKey);
  }

  private storeSession(response: AuthResponse): void {
    this.session.set(response);
    localStorage.setItem(this.storageKey, JSON.stringify(response));
  }

  private readStoredSession(): StoredSession | null {
    try {
      const value = localStorage.getItem(this.storageKey);
      if (!value) {
        return null;
      }

      const session = JSON.parse(value) as StoredSession;
      return this.isExpired(session) ? null : session;
    } catch {
      localStorage.removeItem(this.storageKey);
      return null;
    }
  }

  private isExpired(session: StoredSession): boolean {
    return new Date(session.expiresAtUtc).getTime() <= Date.now();
  }
}
