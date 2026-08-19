import { Controller } from '@hotwired/stimulus';

export default class PresentationController extends Controller {
  static targets = [
    'previousButton',
    'nextButton',
  ];

  previousButtonTarget:HTMLButtonElement;
  nextButtonTarget:HTMLButtonElement;

  private abortController = new AbortController();
  private openFieldsSelector = 'input, textarea, op-ckeditor, [contenteditable]';

  connect() {
    const { signal } = this.abortController;
    window.addEventListener('keydown', this, { signal });
  }

  handleEvent(event:KeyboardEvent) {
    // Ignore key events when user is actively editing
    if (window.OpenProject.pageState === 'edited') {
      return;
    }

    // Ignore key events when focus is on an input, textarea, or contenteditable element
    if ((event.target as HTMLElement).closest(this.openFieldsSelector)) {
      return;
    }

    switch (event.key) {
      case 'ArrowLeft':
        event.preventDefault();
        this.previous();
        break;
      case 'ArrowRight':
      case ' ': // Spacebar
        event.preventDefault();
        this.next();
        break;
    }
  }

  disconnect() {
    this.abortController.abort();
  }

  previous() {
    if (!this.previousButtonTarget.disabled) {
      this.previousButtonTarget.click();
    }
  }

  next() {
    if (!this.nextButtonTarget.disabled) {
      this.nextButtonTarget.click();
    }
  }
}
