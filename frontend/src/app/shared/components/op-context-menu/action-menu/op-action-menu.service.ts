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
  Injectable,
  Injector,
} from '@angular/core';
import { ContextualActionMenu } from 'core-common/contextual-action-menu';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import { OpContextMenuCloseReason } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { OpActionMenuComponent } from './op-action-menu.component';

interface OpenMenu {
  handler:OpContextMenuHandler;
  ref:ComponentRef<OpActionMenuComponent>;
  root:HTMLElement;
  presenter:ContextualActionMenu;
  listeners:AbortController;
  reason:OpContextMenuCloseReason;
}

/**
 * Shows a context menu handler's items as a Primer ActionMenu at the pointer
 * or at the focused element, and hands focus back through the handler's
 * `onClose` with the reason the menu closed.
 */
@Injectable({ providedIn: 'root' })
export class OpActionMenuService {
  private readonly appRef = inject(ApplicationRef);
  private readonly injector = inject(Injector);

  private current:OpenMenu|null = null;

  get active():OpContextMenuHandler|null {
    return this.current?.handler ?? null;
  }

  isActive(handler:OpContextMenuHandler):boolean {
    return this.current?.handler === handler;
  }

  show(handler:OpContextMenuHandler, event:Event, anchor?:HTMLElement):void {
    this.close();

    const items = handler.locals.items.filter((item) => !item.hidden);
    const target = event.target instanceof Element ? event.target.closest(':not(svg, svg *)') : null;
    const invoker = anchor ?? target;
    if (items.length === 0 || !(invoker instanceof HTMLElement)) {
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
      handler, ref, root, listeners, presenter: new ContextualActionMenu(menu), reason: 'outside',
    };
    this.current = opened;

    ref.instance.activated.subscribe(() => this.close('action'));
    document.addEventListener('keydown', (keyboardEvent) => this.handleEscape(keyboardEvent, opened), { signal, capture: true });
    document.addEventListener('pointerdown', (pointerEvent) => {
      const { target } = pointerEvent;
      const inside = target instanceof Node && (menu.contains(target) || !!anchor?.contains(target));
      if (!inside) {
        this.close('outside');
      }
    }, { signal, capture: true });
    menu.overlay.addEventListener('toggle', (toggleEvent) => {
      if ((toggleEvent).newState === 'closed') {
        this.close(opened.reason);
      }
    }, { signal });

    const open = () => {
      if (this.current !== opened) {
        return;
      }
      if (!anchor && event instanceof MouseEvent && event.clientX > 0) {
        opened.presenter.openAtPoint(event.clientX, event.clientY, invoker);
      } else {
        const rect = invoker.getBoundingClientRect();
        opened.presenter.openAtPoint(rect.left, rect.bottom, invoker);
      }
    };

    // Chrome fires contextmenu while the right button is still down, and the
    // trailing pointerup would light-dismiss a popover opened now.
    if (event instanceof MouseEvent && event.type === 'contextmenu' && (event.buttons & 2) !== 0) {
      document.addEventListener('pointerup', open, { once: true, capture: true, signal });
    } else {
      open();
    }
  }

  close(reason?:OpContextMenuCloseReason):void {
    const opened = this.current;
    if (!opened) {
      return;
    }

    this.current = null;
    opened.listeners.abort();
    opened.presenter.destroy();

    // Removing the open popover, rather than hiding it, skips the browser's
    // focus restore and the element's own refocus of the invoker: focus lands
    // on the body and the handler alone decides where it goes.
    this.dispose(opened);
    opened.handler.onClose(false, reason ?? opened.reason);
  }

  private dispose({ ref, root }:OpenMenu):void {
    this.appRef.detachView(ref.hostView);
    ref.destroy();
    root.remove();
  }

  // Escape inside an open submenu steps back one level; anywhere else it closes the
  // menu, as the popover's own light dismiss does for a real key press. Handling
  // it here also covers scripted key events and a press before focus moved in.
  private handleEscape(event:KeyboardEvent, opened:OpenMenu):void {
    if (event.key !== 'Escape') {
      return;
    }

    event.preventDefault();
    const menu = opened.ref.instance.menuElement;
    const level = event.target instanceof Element ? event.target.closest<HTMLElement>('anchored-position') : null;
    if (level && menu.contains(level) && level !== menu.overlay && level.matches(':popover-open')) {
      level.hidePopover();
      return;
    }

    this.close('escape');
  }
}
