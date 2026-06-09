import { ApplicationController } from 'stimulus-use';
import { announce } from '@primer/live-region-element';

export const SUCCESS_AUTOHIDE_TIMEOUT = 5000;
export const FLASH_ANNOUNCEMENT_DELAY = 500;

export default class FlashController extends ApplicationController {
  static values = {
    autohide: Boolean,
  };

  static targets = [
    'item',
    'flash',
  ];

  declare autohideValue:boolean;
  declare readonly itemTargets:HTMLElement[];

  private autohideTimers = new WeakMap<HTMLElement, number>();

  reloadPage() {
    window.location.reload();
  }

  itemTargetConnected(element:HTMLElement) {
    this.announceFlash(element);

    const autohide = element.dataset.autohide === 'true';
    if (this.autohideValue && autohide) {
      this.startAutohideTimer(element);
    }
  }

  itemTargetDisconnected(element:HTMLElement) {
    this.clearAutohideTimer(element);
  }

  flashTargetDisconnected() {
    this.itemTargets.forEach((target:HTMLElement) => {
      if (target.innerHTML === '') {
        target.remove();
      }
    });
  }

  private startAutohideTimer(element:HTMLElement) {
    this.resumeAutohideTimer(element);
    element.addEventListener('focusin', () => this.pauseAutohideTimer(element));
    element.addEventListener('focusout', () => this.resumeAutohideTimer(element));
    element.addEventListener('mouseenter', () => this.pauseAutohideTimer(element));
    element.addEventListener('mouseleave', () => this.resumeAutohideTimer(element));
  }

  private announceFlash(element:HTMLElement) {
    if (document.documentElement.hasAttribute('data-turbo-preview')) {
      return;
    }

    const message = element.dataset.announcement;
    if (!message) {
      return;
    }

    const politeness = element.dataset.politeness === 'assertive' ? 'assertive' : 'polite';

    window.setTimeout(() => {
      if (!element.isConnected) {
        return;
      }

      void announce(message, { politeness, from: element });
    }, FLASH_ANNOUNCEMENT_DELAY);
  }

  private pauseAutohideTimer(element:HTMLElement) {
    const timeoutId = this.autohideTimers.get(element);
    if (timeoutId) {
      window.clearTimeout(timeoutId);
      this.autohideTimers.delete(element);
    }
  }

  private resumeAutohideTimer(element:HTMLElement) {
    if (this.autohideTimers.has(element) || this.isBeingInteractedWith(element)) {
      return;
    }

    const timeoutId = window.setTimeout(() => element.remove(), SUCCESS_AUTOHIDE_TIMEOUT);
    this.autohideTimers.set(element, timeoutId);
  }

  private clearAutohideTimer(element:HTMLElement) {
    const timeoutId = this.autohideTimers.get(element);
    if (timeoutId) {
      window.clearTimeout(timeoutId);
    }

    this.autohideTimers.delete(element);
  }

  private isBeingInteractedWith(element:HTMLElement) {
    return element.matches(':hover') || element.contains(document.activeElement);
  }
}
