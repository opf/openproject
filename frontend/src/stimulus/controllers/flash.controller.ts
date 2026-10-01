//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ApplicationController } from 'stimulus-use';
import { announce } from '@primer/live-region-element';

export const SUCCESS_AUTOHIDE_TIMEOUT = 5000;
// Match Primer's live-region registration delay. Manual screen reader
// testing showed the first announcement can be missed without this pause.
export const LIVE_REGION_ANNOUNCEMENT_DELAY = 150;

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
    // Announce the flash message to screen readers via global live region
    this.announceFlash(element);

    // Schedule auto-hide timer if enabled for both controller and individual element
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
    // Pause auto-hide when user interacts with the flash message via keyboard or mouse
    element.addEventListener('focusin', () => this.pauseAutohideTimer(element));
    element.addEventListener('focusout', () => this.resumeAutohideTimer(element));
    element.addEventListener('mouseenter', () => this.pauseAutohideTimer(element));
    element.addEventListener('mouseleave', () => this.resumeAutohideTimer(element));
  }

  // Announces a flash message to screen readers via global live region.
  private announceFlash(element:HTMLElement) {
    // Skip announcements during Turbo cached preview rendering to avoid noise
    if (document.documentElement.hasAttribute('data-turbo-preview')) {
      return;
    }

    // Extract announcement text from element data attribute
    const message = element.dataset.announcement;
    if (!message) {
      return;
    }

    // Determine politeness level: 'assertive' for errors/alerts, 'polite' for other messages
    const politeness = element.dataset.politeness === 'assertive' ? 'assertive' : 'polite';

    // Defer announcement so screen readers can observe the live region before it changes.
    window.setTimeout(() => {
      if (!element.isConnected) {
        return;
      }

      void announce(message, { politeness, from: element });
    }, LIVE_REGION_ANNOUNCEMENT_DELAY);
  }

  /**
   * Pauses the auto-hide timer for an element (called on user interaction).
   * Clears any existing timer without restarting it.
   */
  private pauseAutohideTimer(element:HTMLElement) {
    this.clearAutohideTimer(element);
  }

  /**
   * Resumes the auto-hide timer for an element.
   * Only starts if no timer exists and user is not actively interacting with the element.
   *
   * WCAG 2.1 §2.2.4 (Pause, Stop, Hide): Allows users to pause auto-dismissing content
   * while they're reading or interacting with it.
   */
  private resumeAutohideTimer(element:HTMLElement) {
    // Don't restart if timer already exists or user is currently interacting
    if (this.autohideTimers.has(element) || this.isBeingInteractedWith(element)) {
      return;
    }

    // Schedule element removal after timeout
    const timeoutId = window.setTimeout(() => element.remove(), SUCCESS_AUTOHIDE_TIMEOUT);
    this.autohideTimers.set(element, timeoutId);
  }

  /**
   * Clears the auto-hide timer when an element is removed from the DOM.
   * Prevents orphaned timers from holding memory (though WeakMap helps here too).
   */
  private clearAutohideTimer(element:HTMLElement) {
    const timeoutId = this.autohideTimers.get(element);
    if (timeoutId) {
      window.clearTimeout(timeoutId);
    }

    this.autohideTimers.delete(element);
  }

  /**
   * Checks if the user is currently interacting with the element.
   * Used to avoid resuming auto-hide timers while the user is actively using the message.
   */
  private isBeingInteractedWith(element:HTMLElement) {
    return element.matches(':hover') || element.contains(document.activeElement);
  }
}
