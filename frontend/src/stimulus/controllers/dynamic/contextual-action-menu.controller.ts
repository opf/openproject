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
// Keep using the strict variant — a drag-gating variant treats far more of the
// card as interactive and would hand most right-clicks back to the browser.
import { closestInteractiveElement } from 'core-common/interactive-element-helper';

type InvocationOrigin = 'pointer'|'keyboard';

function isContextMenuKey(event:KeyboardEvent):boolean {
  return event.key === 'ContextMenu' || (event.shiftKey && event.key === 'F10');
}

/**
 * Presents the action menu of the element it is attached to as a context menu.
 *
 * Attach it alongside whatever controller owns the element's ordinary
 * behaviour; this controller adds only the contextual entry points and never
 * touches navigation, selection, or the menu's contents. Listeners of the
 * cancelable `contextual-action-menu:beforeOpen` event can suppress or prepare
 * an invocation — the seam a later batch-selection slice uses.
 *
 * `beforeOpen` means "an invocation was attempted", not "a menu is about to
 * appear". It fires at gesture time, because whether to call preventDefault()
 * on the browser's own context menu has to be decided there and then, while
 * the pointer path opens the menu later, at the release. So a menu need never
 * follow the event: the gesture may be cancelled, the pointer may leave the
 * window, or a second invocation may supersede the first — and a right-click
 * repeated before its release fires `beforeOpen` twice for the one menu that
 * eventually opens. A listener applying selection or other preparatory state
 * must be idempotent and must not assume a matching "opened" ever arrives.
 */
export default class ContextualActionMenuController extends Controller<HTMLElement> {
  static elements = { menu: 'action-menu' };

  // Provided by the stimulus-elements blessing; absent when the host element
  // has no action menu, in which case every invocation falls through to the
  // browser's own context menu.
  declare readonly menuElement:ActionMenuElement;
  declare readonly hasMenuElement:boolean;

  private abortController?:AbortController;
  private presenter?:ContextualActionMenu;
  // The element the current presenter was built for. `menuElement` is a live
  // getter (a fresh querySelector on every access, see the stimulus-elements
  // blessing), not a stable reference, so this is what lets the getter below
  // notice a morph or turbo-stream update that swapped the action-menu
  // subtree while this controller's host element stayed connected.
  private presenterMenu?:ActionMenuElement;
  // Set by a handled keyboard invocation, cleared by the echo it may produce
  // or by any pointer press. A real right-click is always preceded by a
  // mousedown; the browser's keyboard-generated contextmenu event never is,
  // so this needs no timing window and cannot swallow a genuine right-click.
  private expectKeyboardEcho = false;
  // Whether a pointer is currently held down on this element. Read by
  // onContextMenu to tell the two platform orderings apart — see the comment
  // there. Set from `pointerdown` as well as `mousedown` because Chrome emits
  // no `mousedown` at all before a long-press contextmenu; the release
  // listeners sit on the document in capture phase so the flag does not depend
  // on the release bubbling back to this element (a native HTML5 drag ends in
  // `dragend`, not `mouseup`) nor on descendants leaving propagation alone.
  private pointerIsDown = false;
  // The kind of pointer that last pressed this element, as reported by
  // `pointerdown`. Read by onContextMenu to keep the browser's own long-press
  // menu for touch and pen — see the comment there.
  private pointerType = '';
  // The pointer path's open, waiting for the release that ends the gesture;
  // aborting it removes the release listeners. At most one is ever pending.
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

  // Any pointer press means the next contextmenu event, if one comes, is a
  // real right-click rather than the echo of a keyboard invocation. Both
  // `pointerdown` and `mousedown` route here: a mouse fires both, a long press
  // fires only the former, and a driver-synthesised gesture may fire only the
  // latter.
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

      // Browsers that ignore the keydown's preventDefault still emit this
      // event against the focused card. The menu is already open where its
      // own show button opens it, so suppress the browser menu without
      // reopening anything. A right-click on a descendant is never this echo.
      if (event.target === this.element) {
        event.preventDefault();
        return;
      }
    }

    // Touch and pen reach this event through a long press, and AGILE-348
    // covers the mouse and keyboard invocations only: there is no touch-sized
    // design for the menu, no way to reach it other than the gesture the
    // browser already spends on its own menu, and no coverage for either.
    // Bailing here — before preventDefault(), and before announcing an
    // invocation that is not going to happen — leaves the native long-press
    // menu exactly as it is today. Replacing it is a deliberate slice of its
    // own, not a side effect of this one. An empty pointerType means no
    // pointerdown was seen and the gesture is treated as a mouse.
    if (this.pointerType !== '' && this.pointerType !== 'mouse') {
      return;
    }

    if (!this.canPresent(event.target)) {
      return;
    }

    // Decided from the DOM as the gesture found it, before `beforeOpen` gets
    // to run: a listener may replace the action-menu subtree, and where this
    // invocation belongs was settled by where the user right-clicked.
    const atInvoker = this.invokerTargeted(event.target);

    if (!this.announceInvocation('pointer')) {
      return;
    }

    event.preventDefault();

    // Chrome light-dismisses a `popover="auto"` that was opened while the
    // right-click gesture is still in flight: the trailing pointerup lands
    // outside the freshly opened popover, counts as an outside click, and
    // closes it again within the same gesture (`toggle open` followed by a
    // non-cancelable `toggle closed`). The keyboard path has no trailing
    // pointer event, which is why only this one is affected. A timer does not
    // fix it — Chrome 150 runs a setTimeout(0) scheduled here several
    // milliseconds *before* it dispatches the gesture's own pointerup — so
    // the open is keyed off the real release instead.
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
    // removes the action-menu while the button is held has to be visible to
    // the getter's invalidation at open time.
    //
    // A right-click on the show button itself opens the menu where the button
    // opens it. The pointer is already on the control the menu belongs to, so
    // there is nowhere better to put it, and the position stays the one that
    // button has always produced.
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
    // Opened exactly where the More button opens it. A keyboard user reaching
    // the menu through Shift+F10 and one reaching it through the button are
    // looking at the same card, and a second, card-relative position for the
    // same menu is a difference with nothing behind it. Only the focus return
    // stays contextual: the card invoked the menu, so the card gets focus back.
    //
    // Deliberately synchronous: nothing is racing this one, and callers
    // (including this controller's own tests) observe the menu immediately.
    this.contextualMenu?.openAtInvoker(this.element);
  };

  /**
   * Runs the given open from the pointer release that ends the current
   * gesture, rather than from the contextmenu event itself. See onContextMenu
   * for why the release, and not a timer, is what this waits on.
   */
  private openOnRelease(openMenu:() => void):void {
    // At most one open is ever pending: a second right-click arriving while
    // this one waits retires it, so the release opens the menu once, at the
    // latest invocation's position.
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

      // disconnect() cancels this explicitly; the controller's own signal is
      // the backstop for any path where that tracking slips. Never open
      // against a disconnected controller.
      if (controllerSignal.aborted) {
        return;
      }

      openMenu();
    };

    const cancel = ():void => this.cancelPendingOpen();

    // On the document, capture phase: the release opens the menu wherever it
    // lands (the pointer may have left the card while the button was held)
    // and before anything else reacts to it.
    doc.addEventListener('pointerup', open, { capture: true, signal });
    doc.addEventListener('mouseup', open, { capture: true, signal });
    // If the release never arrives at all — the pointer left the window, the
    // gesture was cancelled — the pending open must not survive into some
    // later, unrelated click. The next gesture's own press retires it.
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
    // keep the browser's menu: a right-click on the control whose whole job is
    // to open this menu should open this menu. It has to be tested before the
    // guards below, both of which would otherwise claim it.
    if (this.invokerTargeted(target)) {
      return true;
    }

    // Right-clicking inside the open menu, or on a link, button, field, or
    // other meaningful control on the card, keeps the browser's own menu.
    // `closestInteractiveElement` stops at the host element, so the host's own
    // tab stop does not count as an interactive descendant.
    if (this.menuElement.contains(target)) {
      return false;
    }

    return closestInteractiveElement(target, this.element) === null;
  }

  // Whether the gesture landed on the menu's show button (or something inside
  // it, such as the icon). Such an invocation opens the menu where the button
  // itself would, rather than at the pointer.
  private invokerTargeted(target:EventTarget|null):boolean {
    if (!this.hasMenuElement || !(target instanceof Node)) {
      return false;
    }

    return this.menuElement.invokerElement?.contains(target) ?? false;
  }

  // Announces an *attempted* invocation, not an imminent menu: on the pointer
  // path this fires at gesture time while the open waits for the release, so
  // it may fire without a menu ever appearing, and twice for one that does.
  // See the class docstring for what a listener may rely on.
  private announceInvocation(origin:InvocationOrigin):boolean {
    const event = this.dispatch('beforeOpen', {
      detail: { origin },
      cancelable: true,
    });

    return !event.defaultPrevented;
  }

  private get contextualMenu():ContextualActionMenu|undefined {
    const menu = this.hasMenuElement ? this.menuElement : undefined;

    // A morph or turbo-stream update can replace the action-menu subtree, or
    // remove it outright, without this controller ever disconnecting — and
    // `canPresent()` having passed for this invocation before that happened
    // is exactly what lets this getter still run with no menu left at all
    // (a synchronous `beforeOpen` listener that drops the element without
    // cancelling is one way that happens). This comparison runs before the
    // "no menu" return below on purpose: a vanished menu must retire the
    // stale presenter (restoring the anchoring it took over)
    // just as much as a swapped one does, and once the menu is gone,
    // `canPresent()`'s own guard stops every later call from ever reaching
    // this getter again — so this is the last chance to clean up.
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
