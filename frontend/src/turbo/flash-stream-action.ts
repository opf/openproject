import { StreamActions, StreamElement } from '@hotwired/turbo';

export function registerFlashStreamAction() {
  StreamActions.flash = function dialogStreamAction(this:StreamElement) {
    const content = this.templateElement.content;

    const flash = content.querySelector('.flash') as HTMLElement;
    if (flash.dataset.singleton) {
      const elements = document.querySelectorAll('.flash')
      elements.forEach((element) => element.parentElement?.remove());
    }

    document.body.append(content);
  };
}
