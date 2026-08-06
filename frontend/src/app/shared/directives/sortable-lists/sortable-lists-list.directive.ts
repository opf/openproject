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

import {
  DestroyRef,
  Directive,
  ElementRef,
  OnInit,
  inject,
  input,
  output,
} from '@angular/core';
import {
  OpSortableListsDirective,
  type SortableListsDropEvent,
  type SortableListsRemovedEvent,
} from './sortable-lists.directive';

let lastGeneratedId = 0;

function generateListId():string {
  lastGeneratedId += 1;
  return `op-sortable-list-${lastGeneratedId}`;
}

// An explicit list inside an `opSortableLists` root, for roots managing more
// than one drop zone (e.g. a "To do" / "Done" pair). Registering one retires
// the root's implicit list (see `attachList`) and its own outputs take over
// from the root's proxy outputs for drops resolving to this list.
@Directive({
  selector: '[opSortableListsList]',
})
export class OpSortableListsListDirective implements OnInit {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  private readonly destroyRef = inject(DestroyRef);

  // Public so `OpSortableListsItemDirective` can compare owning roots — DI
  // itself has no notion of a nested root boundary.
  readonly root = inject(OpSortableListsDirective);

  // The alias intentionally does not double up "List" (selector + capitalized
  // property name would read `opSortableListsListListId`).
  // eslint-disable-next-line @angular-eslint/no-input-rename
  listId = input<string>(generateListId(), { alias: 'opSortableListsListId' });

  accepts = input<(() => boolean)|null>(null, { alias: 'opSortableListsListAccepts' });

  scrollContainer = input<Element|null>(null, { alias: 'opSortableListsListScrollContainer' });

  opSortableListsDrop = output<SortableListsDropEvent>();

  opSortableListsRemoved = output<SortableListsRemovedEvent>();

  ngOnInit():void {
    const cleanup = this.root.attachList(this);
    this.destroyRef.onDestroy(cleanup);
  }
}
