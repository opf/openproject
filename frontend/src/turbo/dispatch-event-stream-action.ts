import { StreamActions, StreamElement } from '@hotwired/turbo';

export function registerDispatchEventStreamAction() {
  StreamActions.dispatchEvent = function dispatchEventStreamAction(this:StreamElement) {
    const name = this.getAttribute('event-name');
    if (!name) { return; }

    const detail = JSON.parse(this.getAttribute('detail') ?? '{}') as unknown;
    document.dispatchEvent(new CustomEvent(name, { detail }));
  };
}
