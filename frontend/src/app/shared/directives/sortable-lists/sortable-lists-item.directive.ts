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
  signal,
} from '@angular/core';
import {
  draggable,
  dropTargetForElements,
} from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { combine } from '@atlaskit/pragmatic-drag-and-drop/combine';
import { preventUnhandled } from '@atlaskit/pragmatic-drag-and-drop/prevent-unhandled';
import {
  type Edge,
  attachClosestEdge,
  extractClosestEdge,
} from 'core-common/drag-and-drop/reorder';
import { closestInteractiveElement } from 'core-stimulus/helpers/interactive-element-helper';
import { OpSortableListsDirective } from './sortable-lists.directive';

type CleanupFn = () => void;

// One sortable item inside an `opSortableLists` list. Mirrors the Stimulus
// `sortable-lists--item` controller: it registers its host element with
// Pragmatic exactly once per directive instance, so Angular's view lifecycle
// (`@for` track) owns creation and destruction of the registration. Drag and
// drop-position state is exposed through `data-dragging` and
// `data-drop-position` host attributes for the consumer's stylesheet.
@Directive({
  selector: '[opSortableListsItem]',
  host: {
    '[attr.data-dragging]': 'dragging() ? "true" : null',
    '[attr.data-drop-position]': 'dropPosition()',
  },
})
export class OpSortableListsItemDirective implements OnInit {
  private readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  private readonly destroyRef = inject(DestroyRef);

  // Fails Angular injection loudly when the item is not placed inside an
  // `opSortableLists` ancestor, instead of silently becoming inert.
  private readonly list = inject(OpSortableListsDirective);

  itemId = input.required<string>({ alias: 'opSortableListsItem' });

  readonly dragging = signal(false);

  readonly dropPosition = signal<Edge|null>(null);

  ngOnInit():void {
    if (!this.itemId()) {
      console.warn(
        'opSortableListsItem requires a non-empty item id; this item will not be draggable.',
        this.elementRef.nativeElement,
      );
      return;
    }

    const cleanup = combine(
      this.registerDraggable(),
      this.registerDropTarget(),
    );

    this.destroyRef.onDestroy(() => {
      this.dragging.set(false);
      this.dropPosition.set(null);
      cleanup();
    });
  }

  private registerDraggable():CleanupFn {
    const element = this.elementRef.nativeElement;

    return draggable({
      element,
      canDrag: ({ input: pointer }) => this.canDragFromPoint(pointer.clientX, pointer.clientY),
      getInitialData: () => this.list.payloadScope.itemData(this.itemId()),
      onDragStart: () => {
        preventUnhandled.start();
        this.dragging.set(true);
      },
      onDrop: () => {
        preventUnhandled.stop();
        this.dragging.set(false);
      },
    });
  }

  private registerDropTarget():CleanupFn {
    const element = this.elementRef.nativeElement;
    const { payloadScope } = this.list;

    return dropTargetForElements({
      element,
      canDrop: ({ source }) => payloadScope.isItemData(source.data)
        && source.data.itemId !== this.itemId(),
      getData: ({ input: pointer }) => attachClosestEdge(payloadScope.itemData(this.itemId()), {
        element,
        input: pointer,
        allowedEdges: this.list.allowedEdges(),
      }),
      getIsSticky: ({ input: pointer }) => this.list.containsPoint(pointer),
      onDragEnter: ({ self }) => this.dropPosition.set(extractClosestEdge(self.data)),
      onDrag: ({ self }) => this.dropPosition.set(extractClosestEdge(self.data)),
      onDragLeave: () => this.dropPosition.set(null),
      onDrop: ({ source, self }) => {
        this.dropPosition.set(null);
        this.emitDropIntent(source.data, self.data);
      },
    });
  }

  // The active item target resolves the drop itself, so no global monitor is
  // needed: a drop onto self or from a foreign list never passes canDrop, and
  // a drop outside the list reaches no item target at all.
  private emitDropIntent(
    sourceData:Record<string|symbol, unknown>,
    selfData:Record<string|symbol, unknown>,
  ):void {
    if (!this.list.payloadScope.isItemData(sourceData)) {
      return;
    }

    this.list.emitDrop({
      sourceId: sourceData.itemId,
      targetId: this.itemId(),
      edge: extractClosestEdge(selfData),
    });
  }

  // A drag may not start from an interactive descendant (e.g. the remove
  // button inside a chip), matching the Stimulus sortable-item behavior.
  private canDragFromPoint(clientX:number, clientY:number):boolean {
    const element = this.elementRef.nativeElement;
    const target = element.ownerDocument.elementFromPoint(clientX, clientY);

    if (!(target instanceof Element) || !element.contains(target)) {
      return true;
    }

    return closestInteractiveElement(target, element) == null;
  }
}
