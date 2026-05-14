import { Controller } from '@hotwired/stimulus';

export default class AvatarCropController extends Controller {
  static targets = ['input', 'modal', 'image', 'preview', 'uploadBtn'];
  static values  = { uploadUrl: String, csrfToken: String };

  declare readonly inputTarget: HTMLInputElement;
  declare readonly modalTarget: HTMLElement;
  declare readonly imageTarget: HTMLImageElement;
  declare readonly previewTarget: HTMLElement;
  declare readonly uploadBtnTarget: HTMLButtonElement;
  declare readonly uploadUrlValue: string;
  declare readonly csrfTokenValue: string;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private cropper: any = null;

  fileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file  = input.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => { void this.openModal(e.target?.result as string); };
    reader.readAsDataURL(file);
  }

  private async openModal(src: string): Promise<void> {
    if (this.cropper) { this.cropper.destroy(); this.cropper = null; }

    this.modalTarget.style.display = 'flex';
    document.body.style.overflow   = 'hidden';

    const img = this.imageTarget;

    // Wait for image to load
    await new Promise<void>((resolve) => {
      img.onload = () => resolve();
      img.src    = src;
    });

    // One animation frame so browser paints the image inside the modal
    await new Promise((r) => requestAnimationFrame(r));

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const mod = await import('cropperjs') as any;
    const CropperClass = mod.default ?? mod;

    this.cropper = new CropperClass(img, {
      aspectRatio:              1,
      viewMode:                 1,
      dragMode:                 'move',
      autoCropArea:             0.8,
      restore:                  false,
      guides:                   true,
      center:                   true,
      highlight:                true,
      cropBoxMovable:           true,
      cropBoxResizable:         true,
      toggleDragModeOnDblclick: false,
      preview:                  this.previewTarget,
    });
  }

  closeModal(): void {
    this.modalTarget.style.display = 'none';
    document.body.style.overflow   = '';
    if (this.cropper) { this.cropper.destroy(); this.cropper = null; }
    this.inputTarget.value = '';
  }

  async save(): Promise<void> {
    if (!this.cropper) return;

    const btn = this.uploadBtnTarget;
    btn.disabled    = true;
    btn.textContent = '...';

    try {
      const canvas = this.cropper.getCroppedCanvas({ width: 128, height: 128 }) as HTMLCanvasElement;
      const blob   = await new Promise<Blob>((resolve, reject) => {
        canvas.toBlob(
          (b: Blob | null) => (b ? resolve(b) : reject(new Error('toBlob failed'))),
          'image/jpeg',
          0.9,
        );
      });

      const form = new FormData();
      form.append('file', blob, 'avatar.jpg');

      const res = await fetch(this.uploadUrlValue, {
        method:      'PUT',
        credentials: 'same-origin',
        headers:     { 'X-CSRF-Token': this.csrfTokenValue },
        body:        form,
      });

      if (!res.ok) throw new Error(`Upload failed: ${res.status}`);

      this.closeModal();
      window.location.reload();
    } catch (err) {
      console.error('[avatar-crop] save failed', err);
      btn.textContent = 'Erro';
      btn.disabled    = false;
    }
  }
}
