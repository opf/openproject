import { Controller } from '@hotwired/stimulus';

// Removes the op-logo--loading class (skeleton) once the logo background-image finishes loading.
export default class extends Controller<HTMLElement> {
  connect(): void {
    const bg = window.getComputedStyle(this.element).backgroundImage;
    const match = bg.match(/url\(["']?(.+?)["']?\)/);
    if (!match) { this.done(); return; }

    const img = new Image();
    img.onload  = () => this.done();
    img.onerror = () => this.done();
    img.src = match[1];
    if (img.complete) this.done();
  }

  private done(): void {
    this.element.classList.remove('op-logo--loading');
  }
}
