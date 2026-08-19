/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { ApplicationController } from 'stimulus-use';
import { sanitizeUrl } from '@braintree/sanitize-url';
import { computePosition, flip, limitShift, shift } from '@floating-ui/dom';

/**
 * This controller is responsible for showing a hover card when hovering over a trigger element.
 *
 * You can define a trigger element by adding the `data-hover-card-trigger-target="trigger"` to it.
 * To have hover cards available everywhere, add this controller to the body tag.
 *
 * Please see our guide in the lookbook for more information on how to use hover cards.
 */
export default class HoverCardTriggerController extends ApplicationController {
  static targets = ['trigger', 'card'];

  private readonly triggerTargets:HTMLElement[];

  private mouseInModal = false;
  private mouseIsHoveringOverTrigger = false;
  private hoverTimeout:number|null = null;
  private closeTimeout:number|null = null;
  private previousTarget:HTMLElement|null = null;

  // Track whether we currently show a hover card or not. It is important not to open multiple hover cards at
  // the same time, and refrain from closing the wrong kind of modal overlay.
  private isShowingHoverCard = false;

  // The time you need to keep hovering over a trigger before the hover card is shown
  OPEN_DELAY_IN_MS = 1000;
  // The time you need to keep away from trigger/hover card before an opened card is closed
  CLOSE_DELAY_IN_MS = 250;

  private triggerMouseOverBound= this.onMouseOver.bind(this);
  private triggerMouseLeaveBound= this.onMouseLeave.bind(this);
  private cardMouseLeaveBound= this.onMouseLeave.bind(this);
  private cardMouseEnterBound= this.onMouseEnter.bind(this);

  /**
   * Attempting to show hover cards on touch-based devices often leads to quirky and unwanted
   * behavior. As all information in our hover cards is optional, we'd rather only show them
   * on devices that primarily support a mouse cursor. That means that hovering is a reliable
   * option for interaction.
   */
  shouldRegisterHoverEventListeners() {
    const browserSupportsHovering = window.matchMedia('(hover: hover)').matches;
    // The browser on the CI claims not to support hovering, so we must detect whether we are in a test environment:
    const isTestEnv = window.OpenProject.environment === 'test';

    return isTestEnv || browserSupportsHovering;
  }

  private triggerTargetConnected(trigger:Element) {
    if (this.shouldRegisterHoverEventListeners()) {
      trigger.addEventListener('mouseover', this.triggerMouseOverBound);
      trigger.addEventListener('mouseleave', this.triggerMouseLeaveBound);
    }
  }

  private triggerTargetDisconnected(trigger:Element) {
    trigger.removeEventListener('mouseover', this.triggerMouseOverBound);
    trigger.removeEventListener('mouseleave', this.triggerMouseLeaveBound);
  }

  private cardTargetConnected(card:Element) {
    if (this.shouldRegisterHoverEventListeners()) {
      card.addEventListener('mouseleave', this.cardMouseLeaveBound);
      card.addEventListener('mouseenter', this.cardMouseEnterBound);
    }
  }

  private cardTargetDisconnected(card:Element) {
    card.removeEventListener('mouseleave', this.cardMouseLeaveBound);
    card.removeEventListener('mouseenter', this.cardMouseEnterBound);
  }

  private onMouseLeave() {
    this.clearHoverTimer();
    this.mouseInModal = false;
    this.mouseIsHoveringOverTrigger = false;
    this.closeAfterTimeout();
  }

  private onMouseEnter() {
    this.mouseInModal = true;
  }

  private onMouseOver(e:MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    let el = e.target as HTMLElement;
    if (!el) { return; }

    // If the trigger contains other elements, one of them might have triggered the event. We want to only refer to
    // the original trigger as this makes event and state handling easier. Find the correct target element:
    if (!this.triggerTargets.some((trigger) => trigger === el)) {
      // If the element is not a trigger itself, one of its parents must be. Find the correct one.
      const trigger = el.closest('[data-hover-card-trigger-target="trigger"]')!;

      el = trigger as HTMLElement;
    }

    this.mouseIsHoveringOverTrigger = true;

    if (this.previousTarget && this.previousTarget === el) {
      // Re-entering the trigger counts as hovering over the card:
      this.mouseInModal = true;
      // But we will not re-render the same card, abort here
      return;
    }

    // There is already a hover timer running, do not start a new one.
    if (this.hoverTimeout !== null) { return; }

    // Hovering over a new target. Close the old one (if any).
    this.close(true);

    const turboFrameUrl = this.parseHoverCardUrl(el);
    const popoverTemplate = this.getPopoverTemplateFromId(el);
    if (!turboFrameUrl && !popoverTemplate) { return; }

    // Reset close timer for when hovering over multiple triggers in quick succession.
    // A timer from a previous hover card might still be running. We do not want it to
    // close the new (i.e. this) hover card.
    this.clearCloseTimer();

    // Set a delay before showing the hover card
    this.hoverTimeout = window.setTimeout(() => {
      this.showHoverCard(el, turboFrameUrl, popoverTemplate);
    }, this.OPEN_DELAY_IN_MS);
  }

  private showHoverCard(el:HTMLElement, turboFrameUrl:string, popoverTemplate:HTMLTemplateElement|null) {
    // Abort if the trigger element is no longer present in the DOM. This can happen when this method is called after a delay.
    if (!this.element.contains(el)) { return; }
    // Do not try to show two hover cards at the same time.
    if (this.isShowingHoverCard) { return; }
    // The mouse might have left the trigger while we were waiting for the hover delay.
    if (!this.mouseIsHoveringOverTrigger) { return; }

    if (popoverTemplate) {
      this.showHoverCardViaExistingElement(el, popoverTemplate);
    } else {
      this.loadAndShowHoverCardViaTurboFrame(el, turboFrameUrl);
    }
  }

  private loadAndShowHoverCardViaTurboFrame(targetEl:HTMLElement, turboFrameUrl:string) {
    const overlay = this.getAndResetOverlay();
    if (!overlay) { return; }

    this.moveOverlayToAppropriateParent(overlay, targetEl);

    const { turboFrame, popover } = this.buildPopoverWithTurboFrame(overlay, turboFrameUrl);

    this.isShowingHoverCard = true;
    this.previousTarget = targetEl;

    turboFrame.addEventListener('turbo:frame-load', () => {
      void this.reposition(popover, targetEl);

      // Content has been loaded, card has been positioned. Show it!
      popover.showPopover();
    });
  }

  private showHoverCardViaExistingElement(targetEl:HTMLElement, popoverTemplate:HTMLTemplateElement) {
    const overlay = this.getAndResetOverlay();
    if (!overlay) { return; }

    this.moveOverlayToAppropriateParent(overlay, targetEl);

    const popover = this.popoverFromTemplate(overlay, popoverTemplate);

    this.isShowingHoverCard = true;
    this.previousTarget = targetEl;

    void this.reposition(popover, targetEl);
    popover.showPopover();
  }

  // Should be called when the mouse leaves the hover-zone so that we no longer attempt to display the hover card.
  private clearHoverTimer() {
    if (this.hoverTimeout) {
      clearTimeout(this.hoverTimeout);
      this.hoverTimeout = null;
    }
  }

  private clearCloseTimer() {
    if (this.closeTimeout) {
      clearTimeout(this.closeTimeout);
      this.closeTimeout = null;
    }
  }

  private closeAfterTimeout() {
    this.closeTimeout = window.setTimeout(() => {
      this.close();
    }, this.CLOSE_DELAY_IN_MS);
  }

  private close(forceClose=false) {
    if (forceClose) {
      this.mouseInModal = false;
    }

    if (this.isShowingHoverCard && !this.mouseInModal) {
      this.getAndResetOverlay();

      this.isShowingHoverCard = false;
      // Allow opening this target once more, since it has been orderly closed
      this.previousTarget = null;
    }
  }

  private getAndResetOverlay() {
    const overlay = document.getElementById('hover-card-overlay');
    if (overlay) {
      overlay.innerHTML = '';
      overlay.remove();
    }

    const newOverlay = document.createElement('div');
    newOverlay.id = 'hover-card-overlay';

    return newOverlay;
  }

  /*
   * Will fetch the URL from the element's data attribute and sanitize it.
   * When there is no URL or if the URL is invalid, will return an empty string.
   */
  private parseHoverCardUrl(el:HTMLElement) {
    let url = el.dataset.hoverCardUrl;
    if (!url) { return ''; }

    url = sanitizeUrl(url);

    // `sanitizeUrl` will return 'about:blank' for invalid URLs. We will return an empty-string instead since
    // there's no reason to show an empty hover card.
    return url === 'about:blank' ? '' : url;
  }

  private getPopoverTemplateFromId(el:HTMLElement):HTMLTemplateElement|null {
    const id = el.dataset.hoverCardPopoverTemplateId;
    if (!id) { return null; }

    const element = document.getElementById(id);
    if (!(element instanceof HTMLTemplateElement)) { return null; }

    return element;
  }

  private async reposition(element:HTMLElement, target:HTMLElement) {
    const floatingEl = element;

    const { x, y } = await computePosition(
      target,
      floatingEl,
      {
        placement: 'top',
        middleware: [
          flip({
            mainAxis: true,
            crossAxis: true,
            fallbackAxisSideDirection: 'start',
          }),
          shift({ limiter: limitShift() }),
        ],
      },
    );
    Object.assign(floatingEl.style, {
      left: `${x}px`,
      top: `${y}px`,
    });
  }

  private buildPopoverWithTurboFrame(overlay:HTMLElement, turboFrameUrl:string) {
    const popover = document.createElement('div');
    this.setPopoverAttributes(popover);

    const turboFrame = document.createElement('turbo-frame');
    turboFrame.id = 'op-hover-card-body';
    popover.appendChild(turboFrame);
    turboFrame.setAttribute('src', turboFrameUrl);

    overlay.appendChild(popover);

    return { turboFrame, popover };
  }

  private popoverFromTemplate(overlay:HTMLElement, template:HTMLTemplateElement):HTMLElement {
    const popover = document.createElement('div');
    this.setPopoverAttributes(popover);

    const popoverFragment = document.importNode(template.content, true);
    popover.appendChild(popoverFragment);

    overlay.appendChild(popover);

    return popover;
  }

  private setPopoverAttributes(popover:HTMLElement) {
    popover.classList.add('op-hover-card');
    popover.setAttribute('popover', 'auto');
    popover.dataset.hoverCardTriggerTarget = 'card';
  }

  /*
   * For dialogs, we must ensure that the overlay is a child of the dialog, not the body. Otherwise, the overlay
   * is visible, but cannot be interacted with. This is a bug, see https://github.com/whatwg/html/issues/9936
   *
   * Until this is fixed, we must ensure the popover is interactable. We can do this by checking
   * if the target element is a child of a dialog, and if so, append the hover card overlay to the dialog.
   * Otherwise, we append it to the body.
   */
  private moveOverlayToAppropriateParent(overlay:HTMLElement, targetEl:HTMLElement) {
    const targetParentDialog = targetEl.closest('dialog-helper > dialog');

    if (targetParentDialog) {
      targetParentDialog.appendChild(overlay);
    } else {
      this.element.appendChild(overlay);
    }
  }
}
