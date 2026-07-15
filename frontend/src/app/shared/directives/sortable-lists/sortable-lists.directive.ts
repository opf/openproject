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
  AfterViewInit,
  DestroyRef,
  Directive,
  ElementRef,
  inject,
  input,
  output,
} from '@angular/core';
import { registerAutoScroll } from 'core-common/drag-and-drop/auto-scroll';
import {
  createSortableItemPayloadScope,
} from 'core-common/drag-and-drop/payload';
import { type Edge } from 'core-common/drag-and-drop/reorder';

export type SortableListsAxis = 'vertical'|'horizontal';

export interface SortableListsDropEvent {
  sourceId:string;
  targetId:string;
  edge:Edge|null;
}

// The root of one sortable list whose items are rendered by an Angular
// template. Mirrors the Stimulus `sortable-lists` root controller: it owns
// the state shared by its item directives (payload scope, allowed edges,
// autoscroll, list bounds) and relays their resolved drop intents to the
// owning component. It does not own the consumer's item array and never
// moves DOM — reordering the items in response to the drop output is the
// consumer's job.
@Directive({
  selector: '[opSortableLists]',
})
export class OpSortableListsDirective implements AfterViewInit {
  private readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  private readonly destroyRef = inject(DestroyRef);

  axis = input<SortableListsAxis>('vertical', { alias: 'opSortableListsAxis' });

  scrollContainer = input<Element|null>(null, { alias: 'opSortableListsScrollContainer' });

  opSortableListsDrop = output<SortableListsDropEvent>();

  // One payload scope per list instance: item directives create and
  // recognize drag data through it, so a drag from another list (or any
  // other Pragmatic consumer) is rejected automatically.
  readonly payloadScope = createSortableItemPayloadScope();

  ngAfterViewInit():void {
    const cleanup = registerAutoScroll({
      element: this.scrollContainer() ?? this.closestScrollableAncestor() ?? this.elementRef.nativeElement,
      canScroll: ({ source }) => this.payloadScope.isItemData(source.data),
      axis: 'all',
    });

    this.destroyRef.onDestroy(cleanup);
  }

  allowedEdges():Edge[] {
    return this.axis() === 'horizontal' ? ['left', 'right'] : ['top', 'bottom'];
  }

  // Item targets stay sticky only while the pointer remains over the list,
  // so a drop outside the list cancels instead of reordering next to the
  // last hovered item.
  containsPoint({ clientX, clientY }:{ clientX:number; clientY:number }):boolean {
    const rect = this.elementRef.nativeElement.getBoundingClientRect();

    return clientX >= rect.left
      && clientX <= rect.right
      && clientY >= rect.top
      && clientY <= rect.bottom;
  }

  emitDrop(event:SortableListsDropEvent):void {
    this.opSortableListsDrop.emit(event);
  }

  private closestScrollableAncestor():Element|null {
    let element:HTMLElement|null = this.elementRef.nativeElement;

    while (element) {
      const { overflowX, overflowY } = window.getComputedStyle(element);
      if (/(auto|scroll|overlay)/.test(overflowY + overflowX)) {
        return element;
      }
      element = element.parentElement;
    }

    return null;
  }
}
