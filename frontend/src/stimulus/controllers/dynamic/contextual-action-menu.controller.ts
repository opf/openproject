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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { ContextualActionMenu } from 'core-common/contextual-action-menu';
// The strict variant: a drag-gating one treats far more of the card as
// interactive and would hand most right-clicks back to the browser.
import { closestInteractiveElement } from 'core-common/interactive-element-helper';

type InvocationOrigin = 'pointer'|'keyboard';

function isContextMenuKey(event:KeyboardEvent):boolean {
  return event.key === 'ContextMenu' || (event.shiftKey && event.key === 'F10');
}

/**
 * Presents the action menu of the element it is attached to as a context menu.
 *
 * See the Contextual action menu pattern page in Lookbook for what this offers
 * and what it deliberately leaves to the browser.
 *
 * The cancelable `contextual-action-menu:beforeOpen` event means "an invocation
 * was attempted", not "a menu is about to appear": it fires at gesture time,
 * because whether to preventDefault() the browser's own context menu has to be
 * decided there and then, while the pointer path opens the menu later, at the
 * release. So no menu need follow it — the gesture may be cancelled or
 * superseded — and a right-click repeated before its release fires it twice for
 * the one menu that eventually opens.
 */
export default class ContextualActionMenuController extends Controller<HTMLElement> {
  static elements = { menu: 'action-menu' };

  // Absent when the host element has no action menu, in which case every
  // invocation falls through to the browser's own context menu.
  declare readonly menuElement:ActionMenuElement;
  declare readonly hasMenuElement:boolean;

  private abortController?:AbortController;
  private presenter?:ContextualActionMenu;
  // The element the current presenter was built for. `menuElement` is a live
  // getter, not a stable reference, so this is what lets the getter below
  // notice a morph that swapped the action-menu subtree under a host element
  // that never disconnected.
  private presenterMenu?:ActionMenuElement;
  // A real right-click is always preceded by a mousedown and a
  // keyboard-generated contextmenu event never is, so this needs no timing
  // window and cannot swallow a genuine right-click.
  private expectKeyboardEcho = false;
  // Fed by `pointerdown` as well as `mousedown` because Chrome emits no
  // `mousedown` before a long-press contextmenu, and released from the document
  // in capture phase because a native HTML5 drag ends in `dragend`, not
  // `mouseup`.
  private pointerIsDown = false;
  private pointerType = '';
  private pendingOpen?:AbortController;

  connect():void {
    this.abortController = new AbortController();
    const { signal } = this.abortController;

    this.element.addEventListener('contextmenu', this.onContextMenu, { signal });
    this.element.addEventListener('keydown', this.onKeydown, { signal });
    this.element.addEventListener('pointerdown', this.onPointerDown, { signal });
    this.element.addEventListener('mousedown', this.onPointerPress, { signal });

    const doc = this.element.ownerDocument;
    doc.addEventListener('pointerup', this.onPointerRelease, { capture: true, signal });
    doc.addEventListener('mouseup', this.onPointerRelease, { capture: true, signal });
  }

  disconnect():void {
    this.cancelPendingOpen();
    this.pointerIsDown = false;
    this.pointerType = '';

    this.abortController?.abort();
    this.abortController = undefined;
    this.presenter?.destroy();
    this.presenter = undefined;
    this.presenterMenu = undefined;
  }

  private readonly onPointerDown = (event:PointerEvent):void => {
    this.pointerType = event.pointerType;
    this.onPointerPress();
  };

  // Both `pointerdown` and `mousedown` route here: a mouse fires both, a long
  // press fires only the former, and a driver-synthesised gesture may fire only
  // the latter.
  private readonly onPointerPress = ():void => {
    this.expectKeyboardEcho = false;
    this.pointerIsDown = true;
  };

  private readonly onPointerRelease = ():void => {
    this.pointerIsDown = false;
  };

  private readonly onContextMenu = (event:MouseEvent):void => {
    if (this.expectKeyboardEcho) {
      this.expectKeyboardEcho = false;

      // Browsers that ignore the keydown's preventDefault still emit this event
      // against the focused card. The menu is already open, so suppress the
      // browser's without reopening anything. A right-click on a descendant is
      // never this echo.
      if (event.target === this.element) {
        event.preventDefault();
        return;
      }
    }

    // Touch and pen reach this event through a long press, which AGILE-348
    // deliberately leaves to the browser. Bailing here — before
    // preventDefault(), and before announcing an invocation that is not going
    // to happen — keeps the native long-press menu as it is today. An empty
    // pointerType means no pointerdown was seen; treat it as a mouse.
    if (this.pointerType !== '' && this.pointerType !== 'mouse') {
      return;
    }

    if (!this.canPresent(event.target)) {
      return;
    }

    // Decided from the DOM as the gesture found it, before `beforeOpen` runs: a
    // listener may replace the action-menu subtree, and where this invocation
    // belongs was settled by where the user right-clicked.
    const atInvoker = this.invokerTargeted(event.target);

    if (!this.announceInvocation('pointer')) {
      return;
    }

    event.preventDefault();

    // Chrome light-dismisses a `popover="auto"` opened while the right-click
    // gesture is still in flight: the trailing pointerup lands outside the
    // freshly opened popover, counts as an outside click, and closes it again
    // within the same gesture. A timer does not fix it — Chrome 150 runs a
    // setTimeout(0) scheduled here several milliseconds *before* it dispatches
    // the gesture's own pointerup — so the open is keyed off the real release.
    //
    // The two platform orderings need opposite treatment, and `pointerIsDown`
    // is what tells them apart without sniffing the platform:
    //   * macOS/Chrome fires contextmenu at mousedown time. The release is
    //     still pending, so the open has to wait for it.
    //   * Windows/Linux fire contextmenu at mouseup time. The release has
    //     already landed and no further one is coming, so opening now is both
    //     correct and necessary — waiting would hang forever.
    // Do not "simplify" either branch into a single inline call or a timer.
    //
    // Read the presenter inside the closure, never here: a morph that swaps or
    // removes the action-menu while the button is held has to be visible to the
    // getter's invalidation at open time.
    const { clientX, clientY } = event;
    const open = atInvoker
      ? ():void => this.contextualMenu?.openAtInvoker(this.element)
      : ():void => this.contextualMenu?.openAtPoint(clientX, clientY, this.element);

    if (this.pointerIsDown) {
      this.openOnRelease(open);
    } else {
      open();
    }
  };

  private readonly onKeydown = (event:KeyboardEvent):void => {
    if (!isContextMenuKey(event) || event.target !== this.element) {
      return;
    }

    if (!this.canPresent(event.target) || !this.announceInvocation('keyboard')) {
      return;
    }

    // A keyboard invocation supersedes a right-click still waiting for its
    // release: the menu belongs where the show button puts it, not at the
    // abandoned pointer position, and only one of the two may open.
    this.cancelPendingOpen();

    this.expectKeyboardEcho = true;
    event.preventDefault();
    // Opened exactly where the More button opens it: a keyboard user reaching
    // the menu through Shift+F10 and one reaching it through the button are
    // looking at the same card. Only the focus return stays contextual — the
    // card invoked the menu, so the card gets focus back.
    this.contextualMenu?.openAtInvoker(this.element);
  };

  /**
   * Runs the given open from the pointer release that ends the current
   * gesture, rather than from the contextmenu event itself. See onContextMenu
   * for why the release, and not a timer, is what this waits on.
   */
  private openOnRelease(openMenu:() => void):void {
    // A second right-click arriving while this one waits retires it, so the
    // release opens the menu once, at the latest invocation's position.
    this.cancelPendingOpen();

    const controllerSignal = this.abortController?.signal;
    if (!controllerSignal || controllerSignal.aborted) {
      return;
    }

    const pending = new AbortController();
    this.pendingOpen = pending;
    const { signal } = pending;
    const doc = this.element.ownerDocument;

    const open = ():void => {
      this.cancelPendingOpen();

      // Backstop for any path where disconnect()'s explicit cancel slips:
      // never open against a disconnected controller.
      if (controllerSignal.aborted) {
        return;
      }

      openMenu();
    };

    const cancel = ():void => this.cancelPendingOpen();

    // On the document, capture phase: the release opens the menu wherever it
    // lands (the pointer may have left the card while the button was held) and
    // before anything else reacts to it.
    doc.addEventListener('pointerup', open, { capture: true, signal });
    doc.addEventListener('mouseup', open, { capture: true, signal });
    // Should the release never arrive — pointer left the window, gesture
    // cancelled — the next gesture's own press retires the pending open, so it
    // cannot survive into some later, unrelated click.
    doc.addEventListener('pointerdown', cancel, { capture: true, signal });
    doc.addEventListener('pointercancel', cancel, { capture: true, signal });
  }

  private cancelPendingOpen():void {
    this.pendingOpen?.abort();
    this.pendingOpen = undefined;
  }

  private canPresent(target:EventTarget|null):boolean {
    if (!this.hasMenuElement || !(target instanceof Element)) {
      return false;
    }

    // The menu's own trigger is the one interactive descendant that does not
    // keep the browser's menu, and it has to be tested before the guards below,
    // both of which would otherwise claim it.
    if (this.invokerTargeted(target)) {
      return true;
    }

    // Everything else interactive — the open menu, links, buttons, fields —
    // keeps the browser's own menu. `closestInteractiveElement` stops at the
    // host element, so the host's own tab stop does not count.
    if (this.menuElement.contains(target)) {
      return false;
    }

    return closestInteractiveElement(target, this.element) === null;
  }

  // Whether the gesture landed on the menu's show button, or something inside
  // it such as the icon.
  private invokerTargeted(target:EventTarget|null):boolean {
    if (!this.hasMenuElement || !(target instanceof Node)) {
      return false;
    }

    return this.menuElement.invokerElement?.contains(target) ?? false;
  }

  // Announces an *attempted* invocation, not an imminent menu. See the class
  // docstring for what a listener may rely on.
  private announceInvocation(origin:InvocationOrigin):boolean {
    const event = this.dispatch('beforeOpen', {
      detail: { origin },
      cancelable: true,
    });

    return !event.defaultPrevented;
  }

  private get contextualMenu():ContextualActionMenu|undefined {
    const menu = this.hasMenuElement ? this.menuElement : undefined;

    // Runs before the "no menu" return below on purpose: a vanished menu must
    // retire the stale presenter — restoring the anchoring it took over — just
    // as much as a swapped one does, and once the menu is gone `canPresent()`'s
    // guard stops every later call from reaching this getter, so this is the
    // last chance to clean up.
    if (this.presenter && this.presenterMenu !== menu) {
      this.presenter.destroy();
      this.presenter = undefined;
      this.presenterMenu = undefined;
    }

    if (!menu) {
      return undefined;
    }

    if (!this.presenter) {
      this.presenter = new ContextualActionMenu(menu);
      this.presenterMenu = menu;
    }

    return this.presenter;
  }
}
