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

import { afterNextRender, DestroyRef, Injector } from '@angular/core';
import { isRendered } from 'core-app/shared/helpers/focus-helpers';

export interface RemovalFocusOptions<T> {
  removed:T;
  removedElement:HTMLElement;
  /** The ordered collection; it may still contain the removed item. */
  items:() => readonly T[];
  control:(item:T) => HTMLElement|null|undefined;
  /** Controls to focus when no neighbor offers one, in order of preference. */
  fallback:() => readonly (HTMLElement|null|undefined)[];
  /** The owner of the collection; destroying it cancels the move. */
  injector:Injector;
}

/**
 * Moves focus to the neighbor of an item that is being removed from an
 * ordered collection, so keyboard users do not land on the page body.
 *
 * The item's neighbors are taken on construction: the following ones,
 * then the preceding ones, nearest first. Focus goes to the first of them
 * still in the collection with a rendered control. Any pointer or key
 * input before the move cancels it, as does destroying the owner.
 */
export class RemovalFocus<T> {
  private readonly neighbors:readonly T[];

  private readonly abort = new AbortController();

  private readonly unregisterDestroy:() => void;

  constructor(private readonly options:RemovalFocusOptions<T>) {
    const items = options.items();
    const index = items.indexOf(options.removed);
    this.neighbors = index === -1 ? [] : [...items.slice(index + 1), ...items.slice(0, index).reverse()];

    const cancel = () => this.cancel();
    const { signal } = this.abort;
    document.addEventListener('pointerdown', cancel, { capture: true, signal });
    document.addEventListener('keydown', cancel, { capture: true, signal });
    this.unregisterDestroy = options.injector.get(DestroyRef).onDestroy(() => this.abort.abort());
  }

  focusSuccessorAfterRender():void {
    if (this.abort.signal.aborted) {
      return;
    }
    afterNextRender(() => this.focusSuccessor(), { injector: this.options.injector });
  }

  focusSuccessor():void {
    if (this.abort.signal.aborted) {
      return;
    }
    this.cancel();

    if (!this.focusIsUnowned()) {
      return;
    }

    const { removed, items, control, fallback } = this.options;
    const survivors = new Set(items());
    const neighbors = this.neighbors
      .filter((item) => item !== removed && survivors.has(item))
      .map((item) => control(item));

    [...neighbors, ...fallback()].find(isRendered)?.focus();
  }

  cancel():void {
    if (!this.abort.signal.aborted) {
      this.abort.abort();
      this.unregisterDestroy();
    }
  }

  private focusIsUnowned():boolean {
    const { activeElement } = document;
    return !activeElement || activeElement === document.body || this.options.removedElement.contains(activeElement);
  }
}
