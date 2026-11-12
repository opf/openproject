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

import { DestroyRef, Directive, inject } from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { isTriggerDisabled, OpActionMenuComponent, visibleMenuItems } from './op-action-menu.component';

/**
 * Supplies the items of the `op-action-menu` it sits on each time the menu
 * opens. When `buildItems()` returns a promise, the opening is canceled and
 * the menu opens once the items have arrived, so it never shows empty. It
 * stays closed when there is nothing visible to show or the load fails, and
 * the load is abandoned when the user presses outside the trigger, presses
 * Tab or Escape, the trigger becomes disabled, or the menu is destroyed
 * meanwhile. Programmatic focus changes do not abandon it.
 */
@Directive()
export abstract class OpActionMenuItems extends UntilDestroyedMixin {
  protected readonly menu = inject(OpActionMenuComponent, { self: true });

  private pendingLoad:AbortController|null = null;

  private openingLoaded = false;

  constructor() {
    super();
    this.menu.opening.subscribe((event) => this.onOpening(event));
    this.menu.closed.subscribe(() => this.menu.items.set([]));
    inject(DestroyRef).onDestroy(() => this.abandonLoad());
  }

  protected abstract buildItems():OpContextMenuItem[]|PromiseLike<OpContextMenuItem[]>;

  private onOpening(event:Event):void {
    if (this.openingLoaded) {
      return;
    }
    if (this.pendingLoad) {
      event.preventDefault();
      return;
    }

    const items = this.buildItems();
    if (Array.isArray(items)) {
      if (visibleMenuItems(items).length === 0) {
        event.preventDefault();
        return;
      }
      this.menu.items.set(items);
      return;
    }

    event.preventDefault();
    this.load(items);
  }

  private load(items:PromiseLike<OpContextMenuItem[]>):void {
    const load = new AbortController();
    this.pendingLoad = load;
    this.abandonOnExit(load.signal);

    const arrive = (loaded:OpContextMenuItem[]) => {
      if (this.pendingLoad !== load) {
        return;
      }
      if (visibleMenuItems(loaded).length === 0) {
        this.abandonLoad();
        return;
      }
      // Primer hides the menu a frame after focus leaves it; opening before
      // that check runs would let it close the fresh menu again.
      requestAnimationFrame(() => {
        if (this.pendingLoad === load) {
          this.abandonLoad();
          this.openWith(loaded);
        }
      });
    };
    items.then(arrive, () => arrive([]));
  }

  private abandonOnExit(signal:AbortSignal):void {
    const { menuElement } = this.menu;
    const document = menuElement.ownerDocument;
    const invoker = menuElement.invokerElement;
    if (invoker) {
      const observer = new MutationObserver(() => {
        if (isTriggerDisabled(invoker)) {
          this.abandonLoad();
        }
      });
      observer.observe(invoker, { attributes: true, attributeFilter: ['disabled', 'aria-disabled'] });
      signal.addEventListener('abort', () => observer.disconnect(), { once: true });
    }
    document.addEventListener('pointerdown', (event) => {
      const { target } = event;
      if (!(target instanceof Node && menuElement.invokerElement?.contains(target))) {
        this.abandonLoad();
      }
    }, { capture: true, signal });
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Tab' || event.key === 'Escape') {
        this.abandonLoad();
      }
    }, { capture: true, signal });
  }

  private abandonLoad():void {
    this.pendingLoad?.abort();
    this.pendingLoad = null;
  }

  private openWith(items:OpContextMenuItem[]):void {
    this.menu.items.set(items);
    this.openingLoaded = true;
    try {
      if (!this.menu.open()) {
        this.menu.items.set([]);
      }
    } finally {
      this.openingLoaded = false;
    }
  }
}
