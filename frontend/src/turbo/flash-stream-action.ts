import { StreamActions, StreamElement } from '@hotwired/turbo';

export function registerFlashStreamAction() {
  StreamActions.flash = function dialogStreamAction(this:StreamElement) {
    const content = this.templateElement.content;
    const flash = content.firstElementChild as HTMLElement;
    const target = document.getElementById('primerized-flash-messages') as HTMLElement;

    if (flash.dataset.uniqueKey) {
      const existingFlash = target.querySelector(`[data-unique-key="${flash.dataset.uniqueKey}"]`);
      if (existingFlash) {
        existingFlash.replaceWith(flash);
        return;
      }
    }

    target.append(flash);
  };
}
