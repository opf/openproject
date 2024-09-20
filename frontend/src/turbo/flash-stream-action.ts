import { StreamActions, StreamElement } from '@hotwired/turbo';

export function registerFlashStreamAction() {
  StreamActions.flash = function dialogStreamAction(this:StreamElement) {
    const content = this.templateElement.content;
    const target = document.getElementById('primerized-flash-messages') as HTMLElement;
    target.innerHTML = '';
    target.append(content);
  };
}
