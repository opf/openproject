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

import {
  DestroyRef,
  Directive,
  ElementRef,
  OnInit,
  inject,
  input,
} from '@angular/core';
import { OpSortableListsDirective } from './sortable-lists.directive';
import { OpSortableListsListDirective } from './sortable-lists-list.directive';

// One sortable item inside an `opSortableLists` root. Registers its host
// element with the shared engine once per directive instance in `ngOnInit`
// and cleans up via `DestroyRef`, so a re-rendered item (`@for` track) is a
// fresh registration, not a stale one reused out of order. All drag/
// drop-position visual state is written directly to the host by the engine.
@Directive({
  selector: '[opSortableListsItem]',
})
export class OpSortableListsItemDirective implements OnInit {
  private readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  private readonly destroyRef = inject(DestroyRef);

  // Fails Angular injection loudly when the item is not placed inside an
  // `opSortableLists` ancestor, instead of silently becoming inert.
  private readonly root = inject(OpSortableListsDirective);

  // The nearest explicit list, if any; falls back to the root's own
  // implicit list when the item sits directly under a collapsed root.
  private readonly list = inject(OpSortableListsListDirective, { optional: true });

  itemId = input.required<string>({ alias: 'opSortableListsItem' });

  canDrag = input<boolean>(true, { alias: 'opSortableListsItemCanDrag' });

  ngOnInit():void {
    if (!this.itemId()) {
      console.warn(
        'opSortableListsItem requires a non-empty item id; this item will not be draggable.',
        this.elementRef.nativeElement,
      );
      return;
    }

    // DI's nearest-list lookup does not stop at an intervening
    // `opSortableLists` root: an item under a collapsed root nested inside an
    // outer root's explicit list would otherwise resolve to the OUTER list,
    // while `this.root` resolves to the INNER root — pairing the inner engine
    // with a list id it never registered. Only honor the injected list when
    // it belongs to this item's own nearest root; else fall back to that
    // root's implicit list.
    const ownList = this.list?.root === this.root ? this.list : null;

    const cleanup = this.root.registerItem({
      element: this.elementRef.nativeElement,
      itemId: this.itemId(),
      listId: ownList?.listId() ?? this.root.implicitListId,
      canDrag: () => this.canDrag(),
    });

    this.destroyRef.onDestroy(cleanup);
  }
}
