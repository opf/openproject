import { Controller } from '@hotwired/stimulus';

export default class DisableWhenClickedController extends Controller<HTMLElement> {
  static values = {
    text: String,
  };

  declare textValue:string;
  private alreadyClicked = false;
  private clickListener = this.handleClick.bind(this);

  connect() {
    super.connect();
    this.element.addEventListener('click', this.clickListener);
  }

  disconnect() {
    this.element.removeEventListener('click', this.clickListener);
  }

  private handleClick(event:Event):void {
    if (this.alreadyClicked) {
      event.preventDefault();
      event.stopImmediatePropagation();
      return;
    }

    this.alreadyClicked = true;
    setTimeout(() => this.disable());
  }

  private disable():void {
    const el = this.element;

    // Only form elements support the `disabled` attribute. For other elements
    // (e.g. anchors) fall back to `aria-disabled`, which keeps them focusable
    // for assistive tech. Actual click prevention is handled by the
    // `alreadyClicked` guard.
    if (el instanceof HTMLButtonElement || el instanceof HTMLInputElement) {
      el.disabled = true;
    } else {
      el.setAttribute('aria-disabled', 'true');
    }

    if (this.textValue) {
      el.textContent = this.textValue;
    }
  }
}
