import { DOCUMENT } from '@angular/common';
import { Injectable, computed, inject, signal } from '@angular/core';
import { AuthService } from '../auth/auth.service';

@Injectable({ providedIn: 'root' })
export class AvatarService {
  private readonly auth = inject(AuthService);
  private readonly document = inject(DOCUMENT);
  private readonly revision = signal(0);
  readonly initials = computed(() => {
    const user = this.auth.currentUser();
    return [user?.firstName, user?.lastName].map(name => name?.trim().charAt(0) ?? '').join('').toUpperCase()
      || user?.email?.charAt(0).toUpperCase() || '?';
  });
  readonly photo = computed(() => {
    this.revision();
    const userId = this.auth.currentUser()?.id;
    if (!userId) return null;
    try {
      const value = this.document.defaultView?.localStorage.getItem(this.key(userId));
      return value && /^data:image\/jpeg;base64,[A-Za-z0-9+/=]+$/.test(value) ? value : null;
    } catch { return null; }
  });

  async upload(file: File): Promise<void> {
    const userId = this.auth.currentUser()?.id;
    if (!userId) throw new Error('Sign in to change your photo.');
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) throw new Error('Choose a JPG, PNG or WebP image.');
    if (file.size > 5 * 1024 * 1024) throw new Error('The image must be smaller than 5 MB.');
    const url = URL.createObjectURL(file);
    let photo: string;
    try {
      const image = new Image();
      image.src = url;
      await image.decode();
      const canvas = this.document.createElement('canvas');
      canvas.width = canvas.height = 256;
      const context = canvas.getContext('2d');
      if (!context) throw new Error('Canvas unavailable');
      const side = Math.min(image.naturalWidth, image.naturalHeight);
      context.fillStyle = '#171a21';
      context.fillRect(0, 0, 256, 256);
      context.drawImage(image, (image.naturalWidth - side) / 2, (image.naturalHeight - side) / 2, side, side, 0, 0, 256, 256);
      photo = canvas.toDataURL('image/jpeg', 0.85);
    } catch { throw new Error('Could not read this image. Try another photo.'); }
    finally { URL.revokeObjectURL(url); }
    if (this.auth.currentUser()?.id !== userId) throw new Error('Sign in to change your photo.');
    try {
      const storage = this.document.defaultView?.localStorage;
      if (!storage) throw new Error('Storage unavailable');
      storage.setItem(this.key(userId), photo);
    } catch { throw new Error('Could not save your photo in this browser.'); }
    this.revision.update(value => value + 1);
  }

  remove(): void {
    const userId = this.auth.currentUser()?.id;
    if (!userId) return;
    try { this.document.defaultView?.localStorage.removeItem(this.key(userId)); }
    catch { throw new Error('Could not remove your photo.'); }
    this.revision.update(value => value + 1);
  }

  private key(userId: string): string { return `ironlog.avatar.${userId}`; }
}
