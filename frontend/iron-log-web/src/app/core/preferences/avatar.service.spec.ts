import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { AvatarService } from './avatar.service';
import { AuthService } from '../auth/auth.service';
import { AuthenticatedUser } from '../auth/auth.models';

describe('AvatarService', () => {
  const user = signal<AuthenticatedUser | null>(null);
  let service: AvatarService;
  const account = { id: 'avatar-test-a', firstName: 'George', lastName: 'Xanthos', email: 'test@example.invalid' };

  async function photoFile(): Promise<File> {
    const canvas = document.createElement('canvas');
    canvas.width = 80;
    canvas.height = 40;
    const context = canvas.getContext('2d')!;
    context.fillStyle = '#008080';
    context.fillRect(0, 0, 80, 40);
    const blob = await new Promise<Blob>(resolve => canvas.toBlob(value => resolve(value!), 'image/png'));
    return new File([blob], 'avatar.png', { type: 'image/png' });
  }

  beforeEach(() => {
    localStorage.removeItem('ironlog.avatar.avatar-test-a');
    localStorage.removeItem('ironlog.avatar.avatar-test-b');
    user.set(account);
    TestBed.configureTestingModule({ providers: [{ provide: AuthService, useValue: { currentUser: user } }] });
    service = TestBed.inject(AvatarService);
  });
  afterEach(() => {
    localStorage.removeItem('ironlog.avatar.avatar-test-a');
    localStorage.removeItem('ironlog.avatar.avatar-test-b');
  });

  it('uses account initials until a photo is added', () => {
    expect(service.initials()).toBe('GX');
    expect(service.photo()).toBeNull();
  });

  it('stores a square thumbnail and restores it after reinitialization', async () => {
    await service.upload(await photoFile());
    const photo = service.photo()!;
    expect(photo.startsWith('data:image/jpeg;base64,')).toBeTrue();
    const image = new Image();
    image.src = photo;
    await image.decode();
    expect(image.naturalWidth).toBe(256);
    expect(image.naturalHeight).toBe(256);
    const restored = TestBed.runInInjectionContext(() => new AvatarService());
    expect(restored.photo()).toBe(photo);
  });

  it('keeps photos isolated between accounts and hides them after logout', async () => {
    await service.upload(await photoFile());
    const photo = service.photo();
    user.set({ ...account, id: 'avatar-test-b', firstName: 'Other' });
    expect(service.photo()).toBeNull();
    user.set(null);
    expect(service.photo()).toBeNull();
    user.set(account);
    expect(service.photo()).toBe(photo);
  });

  it('removes the photo and returns to initials', async () => {
    await service.upload(await photoFile());
    service.remove();
    expect(service.photo()).toBeNull();
    expect(localStorage.getItem('ironlog.avatar.avatar-test-a')).toBeNull();
    expect(service.initials()).toBe('GX');
  });

  it('rejects unsupported, oversized and corrupt images without losing the previous photo', async () => {
    await service.upload(await photoFile());
    const original = service.photo();
    await expectAsync(service.upload(new File(['svg'], 'avatar.svg', { type: 'image/svg+xml' }))).toBeRejectedWithError('Choose a JPG, PNG or WebP image.');
    await expectAsync(service.upload(new File([new Uint8Array(5 * 1024 * 1024 + 1)], 'large.png', { type: 'image/png' }))).toBeRejectedWithError('The image must be smaller than 5 MB.');
    await expectAsync(service.upload(new File(['not an image'], 'broken.png', { type: 'image/png' }))).toBeRejectedWithError('Could not read this image. Try another photo.');
    expect(service.photo()).toBe(original);
  });

  it('reports storage failure while preserving the previous photo', async () => {
    await service.upload(await photoFile());
    const original = service.photo();
    spyOn(Storage.prototype, 'setItem').and.throwError('Quota exceeded');
    await expectAsync(service.upload(await photoFile())).toBeRejectedWithError('Could not save your photo in this browser.');
    expect(service.photo()).toBe(original);
  });
});
