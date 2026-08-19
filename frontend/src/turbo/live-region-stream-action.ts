import { StreamActions, StreamElement } from '@hotwired/turbo';
import { announce } from '@primer/live-region-element';

export function registerLiveRegionStreamAction() {
  StreamActions.liveRegion = function liveRegionStreamAction(this:StreamElement) {
    const message = this.getAttribute('message');
    if (!message) return;
    const politeness = this.getAttribute('politeness') || 'polite';
    const delay = parseInt(this.getAttribute('delay') ?? '0', 10);
    if (politeness === 'assertive') {
      void announce(message, {
        politeness: 'assertive',
      });
    } else {
      void announce(message, {
        politeness: 'polite',
        delayMs: delay,
      });
    }
  };
}
