import { StreamActions, StreamElement } from '@hotwired/turbo';

export function registerFlashStreamAction() {
  StreamActions.flash = function dialogStreamAction(this:StreamElement) {
    const content = this.templateElement.content;
    const target = document.getElementById('flash-messages');
    target?.append(content);
  };
}
