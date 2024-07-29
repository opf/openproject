import { StreamActions, StreamElement } from '@hotwired/turbo';

export function registerHistoryAction() {
  StreamActions.history = function historyStreamAction(this:StreamElement) {
    const url = this.getAttribute('url');
    const method = this.getAttribute('method');

    switch (method) {
      case 'replace':
        window.history.replaceState({ href: url }, '', url);
        break;
      case 'push':
        window.history.pushState({ href: url }, '', url);
        break;
      default:
        throw new Error(`Unknown history method: ${method}`);
    }
  };
}
