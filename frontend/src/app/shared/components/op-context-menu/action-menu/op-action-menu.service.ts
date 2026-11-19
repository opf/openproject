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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ApplicationRef,
  ComponentRef,
  createComponent,
  ElementRef,
  inject,
  Injector,
  Service,
} from '@angular/core';
import { ContextualActionMenu, PointerReleaseGate } from 'core-common/contextual-action-menu';
import {
  OpActionMenuHost,
  OpActionMenuOptions,
  OpContextMenuCloseReason,
} from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { OpActionMenuComponent, visibleMenuItems } from './op-action-menu.component';

interface OpenMenu {
  handler:OpActionMenuHost;
  ref:ComponentRef<OpActionMenuComponent>;
  root:HTMLElement;
  presenter:ContextualActionMenu;
  listeners:AbortController;
  invoker:HTMLElement;
}

/**
 * Shows a context menu handler's items as a Primer ActionMenu at the pointer
 * or anchored on the invoking element, and hands focus back through the
 * handler's `onClose` with the reason the menu closed.
 */
@Service()
export class OpActionMenuService {
  private readonly appRef = inject(ApplicationRef);
  private readonly injector = inject(Injector);

  private current:OpenMenu|null = null;

  get active():OpActionMenuHost|null {
    return this.current?.handler ?? null;
  }

  isActive(handler:OpActionMenuHost):boolean {
    return this.current?.handler === handler;
  }

  show(handler:OpActionMenuHost, event:Event, options:OpActionMenuOptions = {}):void {
    this.close();

    const { items } = handler.locals;
    const target = event.target instanceof Element ? event.target.closest(':not(svg, svg *)') : null;
    const invoker = options.anchor ?? target;
    if (!visibleMenuItems(items).length || !(invoker instanceof HTMLElement)) {
      return;
    }

    const ref = createComponent(OpActionMenuComponent, {
      environmentInjector: this.appRef.injector,
      elementInjector: this.injector,
    });
    ref.setInput('items', items);
    ref.setInput('label', handler.locals.label ?? '');
    this.appRef.attachView(ref.hostView);
    const root = (ref.location as ElementRef<HTMLElement>).nativeElement;
    if (handler.locals.contextMenuId) {
      root.id = handler.locals.contextMenuId;
    }
    document.body.append(root);
    ref.changeDetectorRef.detectChanges();

    const menu = ref.instance.menuElement;
    const listeners = new AbortController();
    const { signal } = listeners;
    const opened:OpenMenu = {
      handler, ref, root, listeners, invoker, presenter: new ContextualActionMenu(menu),
    };
    this.current = opened;

    ref.instance.activated.subscribe(() => this.close('action'));
    document.addEventListener('keydown', (keyboardEvent) => this.handleEscape(keyboardEvent, opened), { signal, capture: true });
    document.addEventListener('pointerdown', (pointerEvent) => {
      const { target: pressed } = pointerEvent;
      const inside = pressed instanceof Node && (menu.contains(pressed) || !!options.anchor?.contains(pressed));
      if (!inside) {
        this.close('outside');
      }
    }, { signal, capture: true });
    // A keyboard open (Shift+F10, Menu key) sends contextmenu events to the
    // newly focused item until the key is released, including on key repeat.
    // A new key or pointer press in the menu keeps the native menu.
    let openingKeyHeld = !(event instanceof MouseEvent);
    root.addEventListener('pointerdown', () => { openingKeyHeld = false; }, { signal });
    root.addEventListener('keydown', (keyboardEvent) => {
      if (!keyboardEvent.repeat) openingKeyHeld = false;
    }, { signal, capture: true });
    root.addEventListener('contextmenu', (contextEvent) => {
      if (openingKeyHeld) contextEvent.preventDefault();
    }, { signal });
    menu.overlay.addEventListener('toggle', (toggleEvent) => {
      if (toggleEvent.newState === 'closed') {
        this.close('outside');
      }
    }, { signal });

    const open = () => {
      if (this.current !== opened) {
        return;
      }
      if (!options.anchor && event instanceof MouseEvent && (event.button === 2 || event.clientX > 0 || event.clientY > 0)) {
        opened.presenter.openAtPoint(event.clientX, event.clientY, invoker);
      } else {
        opened.presenter.openAtAnchor(invoker, { align: options.align ?? 'start' }, invoker);
      }
      this.exposeOpenMenu(opened, menu.querySelector('[role="menu"]')?.id);
      this.closeWhenInvokerLeavesView(opened);
    };

    if (event instanceof MouseEvent && event.type === 'contextmenu' && (event.buttons & 2) !== 0) {
      const gate = new PointerReleaseGate(document, signal);
      gate.press();
      gate.openOnRelease(open);
    } else {
      open();
    }
  }

  close(reason:OpContextMenuCloseReason = 'outside'):void {
    const opened = this.current;
    if (!opened) {
      return;
    }

    this.current = null;
    opened.listeners.abort();
    opened.presenter.destroy();
    this.exposeClosedMenu(opened);

    // Removing the open popover, rather than hiding it, skips the browser's
    // focus restore and the element's own refocus of the invoker: focus lands
    // on the body and the handler alone decides where it goes.
    this.dispose(opened);
    opened.handler.onClose(false, reason);
  }

  // Primer keeps the overlay on its anchor while the page scrolls, so a menu
  // whose row scrolled away would sit off screen with its actions out of reach.
  // An invoker that was never in view, such as a row clipped by an unsized
  // scroll container, does not count as scrolled away.
  private closeWhenInvokerLeavesView(opened:OpenMenu):void {
    let seen = false;
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        seen = true;
      } else if (seen && this.current === opened) {
        this.close('scroll');
      }
    });
    observer.observe(opened.invoker);
    opened.listeners.signal.addEventListener('abort', () => observer.disconnect(), { once: true });
  }

  private dispose({ ref, root }:OpenMenu):void {
    this.appRef.detachView(ref.hostView);
    ref.destroy();
    root.remove();
  }

  private exposeOpenMenu({ invoker }:OpenMenu, listId:string|undefined):void {
    if (!invoker.matches('button[aria-haspopup]')) {
      return;
    }

    invoker.setAttribute('aria-expanded', 'true');
    if (listId) {
      invoker.setAttribute('aria-controls', listId);
    }
  }

  private exposeClosedMenu({ invoker }:OpenMenu):void {
    if (!invoker.matches('button[aria-haspopup]')) {
      return;
    }

    invoker.setAttribute('aria-expanded', 'false');
    invoker.removeAttribute('aria-controls');
  }

  // Escape closes the deepest open submenu, else the menu, as the popover's own
  // light dismiss does for a real key press. Primer moves focus into a submenu a
  // frame after opening it, so the open submenus, not the event target, pick the
  // level. Stopping the event keeps the component from also closing the menu.
  private handleEscape(event:KeyboardEvent, opened:OpenMenu):void {
    if (event.key !== 'Escape') {
      return;
    }

    event.preventDefault();
    const openSubMenus = opened.ref.instance.menuElement.childPopoverElements.filter((popover) => popover.matches(':popover-open'));
    const deepest = openSubMenus.at(-1);
    if (deepest) {
      deepest.hidePopover();
      event.stopPropagation();
      return;
    }

    this.close('escape');
  }
}
