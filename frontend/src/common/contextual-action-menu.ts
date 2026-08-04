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

import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import type AnchoredPositionElement from '@openproject/primer-view-components/app/components/primer/anchored_position';

// A context menu conventionally grows down and to the right of its invocation
// point. The pair is also what makes the pointer offsets below mean what they
// say: for exactly this side/align combination `getAnchoredPosition` computes
// `top = anchorRect.bottom + anchorOffset` and
// `left = anchorRect.left + alignmentOffset`. Change either constant and the
// two offsets change axis.
export const CONTEXTUAL_ALIGN = 'start';
export const CONTEXTUAL_SIDE = 'outside-bottom';

interface OverlayState {
  anchor:string|null;
  align:string|null;
  side:string|null;
  alignmentOffset:string|null;
}

function restoreAttribute(element:Element, name:string, value:string|null):void {
  if (value === null) {
    element.removeAttribute(name);
  } else {
    element.setAttribute(name, value);
  }
}

/**
 * Carries the vertical pointer offset as an own property on the overlay.
 *
 * `anchorOffset`'s getter reads its attribute as an enum — only `spacious`/`8`
 * mean 8, everything else means 4 — so the attribute cannot carry an arbitrary
 * pixel offset the way `alignment-offset` can. `update()` passes the element
 * itself to `getAnchoredPosition` as the settings object, so an own property
 * shadowing the prototype accessor is what gets a real number through, and
 * deleting it hands the accessor, and the ordinary 4px gap, straight back.
 */
function setAnchorOffset(overlay:AnchoredPositionElement, value:number):void {
  Object.defineProperty(overlay, 'anchorOffset', { configurable: true, value });
}

function clearAnchorOffset(overlay:AnchoredPositionElement):void {
  Reflect.deleteProperty(overlay, 'anchorOffset');
}

/**
 * Presents an existing Primer ActionMenu contextually: at a pointer position
 * on the invoking element, or at the menu's own show button but with the
 * invoking element owning focus afterwards.
 *
 * It owns only presentation: it never decides which actions the menu contains,
 * never mutates menu items, and holds no selection state.
 */
export class ContextualActionMenu {
  private savedState?:OverlayState;
  private returnFocusTo?:HTMLElement;
  private closeListener?:(event:Event) => void;

  constructor(private readonly menu:ActionMenuElement) {}

  /**
   * Opens the menu at a viewport point, anchored on the invoking element so
   * that it keeps tracking that element while the page scrolls.
   *
   * `invoker` — the element the gesture happened on — both anchors the overlay
   * and receives focus back when the menu closes.
   */
  openAtPoint(clientX:number, clientY:number, invoker:HTMLElement):void {
    const overlay = this.overlay;
    const popover = this.menu.popoverElement;
    if (!overlay || !popover) {
      return;
    }

    this.saveOverlayState(overlay);
    this.anchorAtPoint(overlay, invoker, clientX, clientY);
    this.show(overlay, popover, invoker);
  }

  /**
   * Opens the menu where its own show button would open it, leaving Primer's
   * anchoring untouched, and only takes over where focus goes afterwards.
   *
   * This is the keyboard invocation and the right-click on the menu's own
   * trigger. Nothing is overridden here, so nothing is saved — but a contextual
   * invocation that is still open has to be undone, or its pointer offsets
   * would silently reposition this opening.
   */
  openAtInvoker(returnFocusTo:HTMLElement):void {
    const overlay = this.overlay;
    const popover = this.menu.popoverElement;
    if (!overlay || !popover) {
      return;
    }

    // Only if there was something to undo — an untouched overlay is already
    // positioned by Primer.
    if (this.restoreOverlayState(overlay)) {
      overlay.update();
    }

    this.show(overlay, popover, returnFocusTo);
  }

  /**
   * Drops every contextual mutation, so a morph that removes the card
   * mid-invocation cannot leave a rewritten overlay behind.
   */
  destroy():void {
    const overlay = this.overlay;
    if (overlay && this.closeListener) {
      overlay.removeEventListener('toggle', this.closeListener);
    }
    this.closeListener = undefined;
    this.returnFocusTo = undefined;
    if (overlay) {
      this.restoreOverlayState(overlay);
    }
  }

  private get overlay():AnchoredPositionElement|undefined {
    return this.menu.overlay ?? undefined;
  }

  private show(
    overlay:AnchoredPositionElement,
    popover:HTMLElement,
    returnFocusTo:HTMLElement,
  ):void {
    this.returnFocusTo = returnFocusTo;
    this.listenForClose(overlay);

    // Repeated invocation on an already open menu only moves it. Toggling it
    // shut and open again would restart the deferred fragment focus dance.
    if (!popover.matches(':popover-open')) {
      popover.showPopover();
    }
  }

  /**
   * Expresses the pointer position as offsets from the invoking element rather
   * than anchoring to a synthetic element placed at the pointer: a
   * `position: fixed` element pinned at viewport coordinates never moves in
   * viewport space, so every reposition recomputed the same viewport point
   * while the card scrolled away underneath it. Offsets from the card's live
   * rect are recomputed on every `update()`.
   */
  private anchorAtPoint(
    overlay:AnchoredPositionElement,
    anchorElement:HTMLElement,
    clientX:number,
    clientY:number,
  ):void {
    const anchorRect = anchorElement.getBoundingClientRect();

    overlay.anchorElement = anchorElement;
    // The property wins over the `anchor` idref for positioning, but only
    // clearing it to null strips the attribute, so taking over the anchoring
    // has to strip it here. Left in place, the DOM would advertise an anchoring
    // that is no longer in force. `saveOverlayState` captured it for restore.
    overlay.removeAttribute('anchor');
    overlay.setAttribute('align', CONTEXTUAL_ALIGN);
    overlay.setAttribute('side', CONTEXTUAL_SIDE);
    overlay.setAttribute('alignment-offset', `${clientX - anchorRect.left}`);
    setAnchorOffset(overlay, clientY - anchorRect.bottom);
    // Setting anchorElement is a property write, so it does not run the
    // element's attributeChangedCallback; ask for a reposition explicitly.
    overlay.update();
  }

  private saveOverlayState(overlay:AnchoredPositionElement):void {
    if (this.savedState) {
      return;
    }

    this.savedState = {
      anchor: overlay.getAttribute('anchor'),
      align: overlay.getAttribute('align'),
      side: overlay.getAttribute('side'),
      alignmentOffset: overlay.getAttribute('alignment-offset'),
    };
  }

  /** @returns whether there was any contextual state left to undo. */
  private restoreOverlayState(overlay:AnchoredPositionElement):boolean {
    const state = this.savedState;
    this.savedState = undefined;
    if (!state) {
      return false;
    }

    // The property has to go first: it wins over the attribute, so a stale
    // anchor would otherwise survive the re-applied idref. The offsets are as
    // much a part of the borrowed anchoring as the idref — left behind, they
    // would shove the More button's own menu to wherever the last right-click
    // happened to land.
    overlay.anchorElement = null;
    clearAnchorOffset(overlay);
    restoreAttribute(overlay, 'anchor', state.anchor);
    restoreAttribute(overlay, 'align', state.align);
    restoreAttribute(overlay, 'side', state.side);
    restoreAttribute(overlay, 'alignment-offset', state.alignmentOffset);

    return true;
  }

  private listenForClose(overlay:AnchoredPositionElement):void {
    if (this.closeListener) {
      return;
    }

    const listener = (event:Event):void => {
      if (event.target !== overlay || (event as ToggleEvent).newState !== 'closed') {
        return;
      }

      overlay.removeEventListener('toggle', listener);
      this.closeListener = undefined;

      const returnFocusTo = this.returnFocusTo;
      this.returnFocusTo = undefined;

      this.restoreOverlayState(overlay);
      this.restoreFocus(returnFocusTo);
    };

    this.closeListener = listener;
    overlay.addEventListener('toggle', listener);
  }

  // Primer sends focus back to the show button when the menu closes, which is
  // wrong for a contextual invocation: the card, not the button, was the
  // invoker. Only reclaim focus when nothing else has taken it — an activated
  // item may have opened a dialog or moved focus deliberately.
  private restoreFocus(returnFocusTo?:HTMLElement):void {
    if (!returnFocusTo) {
      return;
    }

    const doc = this.menu.ownerDocument;
    requestAnimationFrame(() => {
      // The restore is deferred a frame, so anything that closes and reopens
      // the popover inside one gesture leaves the menu showing by the time it
      // runs. Focus then legitimately sits on the invoker, and treating it as
      // loose — as the check below does for the Escape path — would yank focus
      // out of a menu the user just opened. Clicking the More button is not
      // such a gesture: measured on Chrome 150, light-dismiss never fires for a
      // popover's own invoker, so the click simply closes the menu (AGILE-348
      // QA report).
      if (this.menu.popoverElement?.matches(':popover-open')) {
        return;
      }

      const active = doc.activeElement;
      const focusIsLoose = active === null
        || active === doc.body
        || active === this.menu.invokerElement
        || this.menu.contains(active);

      if (focusIsLoose) {
        returnFocusTo.focus();
      }
    });
  }
}
