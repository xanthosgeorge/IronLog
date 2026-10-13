import { TranslatePipe } from '../../../../core/preferences/translate.pipe';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { AuthService } from '../../../../core/auth/auth.service';
import { LoginRequest, RegisterRequest } from '../../../../core/auth/auth.models';

@Component({
  selector: 'app-login-page',
  imports: [TranslatePipe, FormsModule],
  templateUrl: './login-page.component.html',
  styleUrl: './login-page.component.scss'
})
export class LoginPageComponent {
  isRegistering = false;
  isSubmitting = false;
  errorMessage = '';
  loginForm: LoginRequest = { email: '', password: '' };
  registerForm: RegisterRequest = { firstName: '', lastName: '', email: '', password: '' };

  constructor(
    private readonly auth: AuthService,
    private readonly router: Router,
    private readonly route: ActivatedRoute
  ) {}

  submit(): void {
    this.errorMessage = '';
    const request = this.isRegistering ? this.registerForm : this.loginForm;

    if (!request.email.trim() || !request.password) {
      this.errorMessage = 'Email and password are required.';
      return;
    }

    if (this.isRegistering && (!this.registerForm.firstName.trim() || !this.registerForm.lastName.trim())) {
      this.errorMessage = 'First name and last name are required.';
      return;
    }

    if (this.isRegistering && request.password.length < 8) {
      this.errorMessage = 'Password must be at least 8 characters long.';
      return;
    }

    this.isSubmitting = true;
    const authRequest = this.isRegistering
      ? this.auth.register({ ...this.registerForm, email: this.registerForm.email.trim() })
      : this.auth.login({ ...this.loginForm, email: this.loginForm.email.trim() });

    authRequest.subscribe({
      next: () => {
        const returnUrl = this.route.snapshot.queryParamMap.get('returnUrl');
        this.router.navigateByUrl(returnUrl?.startsWith('/') ? returnUrl : '/dashboard');
      },
      error: (error) => {
        this.errorMessage = typeof error.error === 'string'
          ? error.error
          : 'We could not complete your request. Please try again.';
        this.isSubmitting = false;
      }
    });
  }

  toggleMode(): void {
    this.errorMessage = '';
    this.isRegistering = !this.isRegistering;
  }
}
