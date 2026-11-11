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
  AfterContentChecked,
  afterRenderEffect,
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  computed,
  contentChild,
  CUSTOM_ELEMENTS_SCHEMA,
  DestroyRef,
  ElementRef,
  inject,
  input,
  output,
  viewChild,
} from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import type AnchoredPositionElement from '@openproject/primer-view-components/app/components/primer/anchored_position';
import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { OpContextMenuCloseReason, OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { DynamicIconDirective } from 'core-app/shared/components/primer/dynamic-icon.directive';
import { generateId } from 'core-app/shared/helpers/dom-helpers';
import type { ActionMenuAlign } from 'core-common/contextual-action-menu';
import { OpActionMenuTriggerDirective } from './op-action-menu-trigger.directive';

const SUBMENU_OPENING_KEYS = new Set(['ArrowRight', 'Enter', ' ']);

type KeyedMenuItem = OpContextMenuItem & { key:string; children?:KeyedMenuItem[] };

function baseKey(item:OpContextMenuItem):string {
  if (item.divider) {
    return 'divider';
  }
  if (item.linkText === undefined) {
    return 'item';
  }
  return item.href ? `${item.linkText}|${item.href}` : item.linkText;
}

export function visibleMenuItems(items:OpContextMenuItem[]):KeyedMenuItem[] {
  const shown = items
    .filter((item) => !item.hidden)
    .map(({ children, ...item }):Omit<KeyedMenuItem, 'key'> => (children ? { ...item, children: visibleMenuItems(children) } : item))
    .filter((item) => !item.children || item.children.length > 0)
    .filter((item, index, list) => !item.divider || !list[index - 1]?.divider);
  const trimmed = shown.filter((item, index) => !item.divider || (index > 0 && index < shown.length - 1));

  const repeats = new Map<string, number>();
  return trimmed.map((item) => {
    const base = baseKey(item);
    const ordinal = repeats.get(base) ?? 0;
    repeats.set(base, ordinal + 1);
    return { ...item, key: `${base}:${ordinal}` };
  });
}

/**
 * Renders context menu items as a Primer ActionMenu. The markup mirrors
 * `Primer::Alpha::ActionMenu` with `SubMenuItem`s; the `<action-menu>` element
 * from Primer ViewComponents supplies keyboard handling, focus zones and
 * submenu toggling.
 *
 * A button projected with `opActionMenuTrigger` becomes the menu's show
 * button; without one, a button hidden from view and from assistive technology
 * stands in so the menu can be opened programmatically.
 */
@Component({
  selector: 'op-action-menu',
  templateUrl: './op-action-menu.component.html',
  styles: [`
    .ActionListItem-visual--leading
      inline-size: var(--base-size-16)
      justify-content: center

    // Primer follows scrolling only while the show button is in view.
    .op-action-menu--stand-in
      position: fixed
      inset-block-start: 0
      inset-inline-start: 0
  `],
  imports: [NgTemplateOutlet, IconModule, DynamicIconDirective],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpActionMenuComponent implements AfterContentChecked, AfterViewInit {
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly destroyRef = inject(DestroyRef);

  readonly items = input.required<OpContextMenuItem[]>();
  readonly label = input.required<string>();
  readonly align = input<ActionMenuAlign>('start');
  /** Positions the overlay against this element instead of the invoker. */
  readonly anchor = input<HTMLElement>();

  readonly visibleItems = computed(() => visibleMenuItems(this.items()));

  readonly trigger = contentChild(OpActionMenuTriggerDirective);

  /** Emits after an item's `onClick` handled the activation. */
  readonly activated = output<OpContextMenuItem>();

  /** Emits from the primary overlay's `beforetoggle`, before the list is read. */
  readonly opening = output<void>();

  /** Emits once per primary close, after focus has been settled. */
  readonly closed = output<OpContextMenuCloseReason>();

  readonly menuId = generateId('op-action-menu');

  private readonly actionMenu = viewChild.required<ElementRef<ActionMenuElement>>('actionMenu');

  private readonly overlay = viewChild.required<ElementRef<AnchoredPositionElement>>('overlay');

  private readonly listeners = new AbortController();

  private reason:OpContextMenuCloseReason = 'outside';

  private externalFocus?:AbortController;

  private lastExternalFocus?:HTMLElement;

  private invokerRefocused = false;

  constructor() {
    afterRenderEffect({
      write: () => {
        const anchor = this.anchor();
        if (anchor) {
          this.overlay().nativeElement.anchorElement = anchor;
        }
      },
    });
    this.destroyRef.onDestroy(() => {
      this.listeners.abort();
      this.externalFocus?.abort();
    });
  }

  get menuElement():ActionMenuElement {
    return this.actionMenu().nativeElement;
  }

  // The projected trigger can be swapped after the first render (a header
  // re-renders its button once its column type is known), so the wiring
  // follows every content check rather than running once.
  ngAfterContentChecked():void {
    const trigger = this.trigger()?.element.nativeElement;
    if (trigger) {
      this.wireTrigger(trigger);
    }
  }

  ngAfterViewInit():void {
    const { signal } = this.listeners;
    const { overlay } = this.menuElement;

    overlay.addEventListener('beforetoggle', (event) => {
      if (event.newState === 'open') {
        this.onOpening();
      }
    }, { signal });
    overlay.addEventListener('toggle', (event) => {
      if (event.newState === 'closed') {
        this.onClosed();
      } else {
        this.invoker?.setAttribute('aria-expanded', 'true');
      }
    }, { signal });
    this.host.nativeElement.addEventListener('keydown', (event) => this.onKeydown(event), { capture: true, signal });
  }

  get invokerId():string {
    return this.trigger()?.element.nativeElement.id ?? `${this.menuId}-button`;
  }

  close():void {
    const popover = this.menuElement.popoverElement;
    if (popover?.matches(':popover-open')) {
      popover.hidePopover();
    }
  }

  itemRole(item:OpContextMenuItem):'menuitem'|'menuitemcheckbox'|'menuitemradio' {
    if (item.checked === undefined) return 'menuitem';
    return item.radio ? 'menuitemradio' : 'menuitemcheckbox';
  }

  subMenuId(prefix:string, index:number):string {
    return `${prefix}-${index}`;
  }

  handleClick(item:OpContextMenuItem, event:MouseEvent):void {
    if (item.disabled) {
      event.preventDefault();
      return;
    }

    if (item.onClick?.(event)) {
      event.preventDefault();
      this.reason = 'action';
      this.activated.emit(item);
    }
  }

  private get invoker():HTMLElement|null {
    return this.trigger()?.element.nativeElement ?? null;
  }

  private wireTrigger(trigger:HTMLElement):void {
    if (trigger.getAttribute('popovertarget') === `${this.menuId}-overlay`) {
      return;
    }

    trigger.id ||= generateId('op-action-menu-trigger');
    trigger.setAttribute('type', 'button');
    trigger.setAttribute('popovertarget', `${this.menuId}-overlay`);
    trigger.setAttribute('aria-controls', `${this.menuId}-list`);
    trigger.setAttribute('aria-haspopup', 'menu');
    trigger.setAttribute('aria-expanded', 'false');
  }

  private onOpening():void {
    this.reason = 'outside';
    this.lastExternalFocus = undefined;
    this.invokerRefocused = false;
    this.trackExternalFocus();
    this.opening.emit();
  }

  private onClosed():void {
    this.externalFocus?.abort();
    this.externalFocus = undefined;
    this.invoker?.setAttribute('aria-expanded', 'false');

    const { reason } = this;
    this.reason = 'outside';
    this.restoreExternalFocus();
    this.closed.emit(reason);
  }

  private onKeydown(event:KeyboardEvent):void {
    if (this.opensDisabledSubMenu(event)) {
      event.preventDefault();
      event.stopPropagation();
      return;
    }

    if (event.key !== 'Escape' || !(event.target instanceof Node)) {
      return;
    }

    const menu = this.menuElement;
    const { overlay } = menu;
    if (!overlay.contains(event.target) || menu.childPopoverElements.some((popover) => popover.matches(':popover-open'))) {
      return;
    }

    this.reason = 'escape';
    this.close();
  }

  private opensDisabledSubMenu(event:KeyboardEvent):boolean {
    return SUBMENU_OPENING_KEYS.has(event.key)
      && event.target instanceof Element
      && event.target.matches('[aria-haspopup="menu"][aria-disabled="true"]');
  }

  private trackExternalFocus():void {
    this.externalFocus?.abort();
    this.externalFocus = new AbortController();
    this.host.nativeElement.ownerDocument.addEventListener('focusin', (event) => {
      if (this.invokerRefocused || !(event.target instanceof HTMLElement)) {
        return;
      }
      if (event.target === this.menuElement.invokerElement) {
        this.invokerRefocused = true;
      } else if (!this.menuElement.contains(event.target)) {
        this.lastExternalFocus = event.target;
      }
    }, { capture: true, signal: this.externalFocus.signal });
  }

  // The opf Primer fork's `action-menu` focuses its invoker on every close of
  // the primary overlay (`#handleToggleEvent`), without checking whether the
  // close was a click or a Tab onto another control, and listeners reacting
  // to that refocus (the table moving focus to the header cell) may move it
  // on again. Once the refocus was seen, hand focus back to the element that
  // held it before. Tracked as DREAM-987; drop once the fork guards the
  // refocus.
  private restoreExternalFocus():void {
    const target = this.lastExternalFocus;
    this.lastExternalFocus = undefined;
    if (this.invokerRefocused && target?.isConnected) {
      target.focus();
    }
  }
}
