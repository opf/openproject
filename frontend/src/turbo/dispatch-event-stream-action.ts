import { StreamActions, StreamElement } from '@hotwired/turbo';

// Dedicated namespace for events dispatched via the `dispatchEvent` turbo stream
// action. This is a security boundary: turbo streams can be injected into the
// DOM (e.g. via stored content), so an attacker could otherwise forge arbitrary
// `document` events. Restricting to this prefix keeps the forgeable surface
// disjoint from the general `op:` event namespace (e.g. `op:theme-changed`),
// whose listeners must never be reachable from an injected stream. Every
// server-side `dispatch_event_via_turbo_stream` caller must name its event
// `op-dispatched:<name>`.
const DISPATCHED_EVENT_PREFIX = 'op-dispatched:';

export function registerDispatchEventStreamAction() {
  StreamActions.dispatchEvent = function dispatchEventStreamAction(this:StreamElement) {
    const name = this.getAttribute('event-name');
    if (!name) { return; }

    if (!name.startsWith(DISPATCHED_EVENT_PREFIX)) {
      console.error(`[dispatchEvent] Refusing to dispatch event "${name}": name must start with "${DISPATCHED_EVENT_PREFIX}".`);
      return;
    }

    const detail = JSON.parse(this.getAttribute('detail') ?? '{}') as unknown;
    document.dispatchEvent(new CustomEvent(name, { detail }));
  };
}
