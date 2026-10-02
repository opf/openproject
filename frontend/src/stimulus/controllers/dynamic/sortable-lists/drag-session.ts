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

import { selectionKey, type SelectionItem } from 'core-common/batch-selection';
import { itemAcceptsDestination, type DestinationIdentity } from './list-dom';
import { itemElementsByKey } from './selection';

export const draggingAttribute = 'data-dragging';

// What one drag needs from the root that hosts it.
export interface DragSessionHost {
  readonly rootElement:HTMLElement;
  // 0 means no cap.
  readonly maxBatchSize:number;
  // The items an action from this item applies to, without touching the
  // selection. Never empty: the item itself when nothing wider applies.
  prospectiveMembers(itemElement:HTMLElement):HTMLElement[];
  // Commits the batch: an unselected movable item becomes the selection
  // first. Null when the root runs no selection, so the drop takes the
  // single-item route.
  frozenMembers(itemElement:HTMLElement):SelectionItem[]|null;
  ownedDestinations():DestinationIdentity[];
  liveOwnerDestinationOf(element:HTMLElement):DestinationIdentity|null;
}

export type DragSessionPhase = 'prospective'|'frozen'|'started'|'ended';

// The destinations every member accepts, or null when that is all of them.
// A batch may span lists, so a confined member pins the block to its own
// list, never to the dragged item's.
export function permittedDestinationsFor(
  members:HTMLElement[],
  destinations:DestinationIdentity[],
  ownerDestinationOf:(item:HTMLElement) => DestinationIdentity|null,
):DestinationIdentity[]|null {
  const permitted = destinations
    .filter((destination) => members.every((member) => itemAcceptsDestination(member, destination, ownerDestinationOf)));

  return permitted.length === destinations.length ? null : permitted;
}

/**
 * One drag, from the first `canDrag` read to its single end.
 *
 * Pragmatic asks `canDrag`, then builds the payloads, then renders the
 * preview, then starts the drag; the phases follow that order. Members are
 * resolved once, in the constructor, and stay fixed; freezing happens at
 * most once; `end()` hands the frozen batch out at most once. Rows are held
 * as identities only, so a morph that replaces an element mid-drag cannot
 * leave the session pointing at a node that left the document.
 */
export class DragSession {
  readonly members:HTMLElement[];

  private currentPhase:DragSessionPhase = 'prospective';
  private frozenBatch:SelectionItem[]|null = null;
  private permitted:{ value:DestinationIdentity[]|null }|null = null;
  private owners = new WeakMap<HTMLElement, DestinationIdentity|null>();

  constructor(
    private readonly host:DragSessionHost,
    readonly sourceElement:HTMLElement,
  ) {
    this.members = host.prospectiveMembers(sourceElement);
  }

  get phase():DragSessionPhase {
    return this.currentPhase;
  }

  get size():number {
    return this.members.length;
  }

  get refused():boolean {
    return this.host.maxBatchSize > 0 && this.members.length > this.host.maxBatchSize;
  }

  permittedDestinations():DestinationIdentity[]|null {
    this.permitted ??= {
      value: permittedDestinationsFor(
        this.members,
        this.host.ownedDestinations(),
        (item) => this.ownerDestinationOf(item),
      ),
    };

    return this.permitted.value;
  }

  // Every item drop target asks on each dragover, so the answer is kept for
  // the drag; the root forgets it when a morph may have moved rows.
  ownerDestinationOf(element:HTMLElement):DestinationIdentity|null {
    const remembered = this.owners.get(element);
    if (remembered !== undefined) {
      return remembered;
    }

    const destination = this.host.liveOwnerDestinationOf(element);
    this.owners.set(element, destination);
    return destination;
  }

  forgetOwners():void {
    this.owners = new WeakMap();
  }

  // Returns the batch size for the preview, which Pragmatic renders before
  // the drag starts.
  freeze():number {
    if (this.currentPhase === 'prospective') {
      this.frozenBatch = this.host.frozenMembers(this.sourceElement);
      this.currentPhase = 'frozen';
    }

    return Math.max(1, this.frozenBatch?.length ?? 0);
  }

  start():void {
    if (this.currentPhase === 'started' || this.currentPhase === 'ended') {
      return;
    }

    this.freeze();
    this.currentPhase = 'started';
    this.markRows();
  }

  // A row a morph replaces mid-drag comes back as fresh server HTML without
  // its mark.
  remark():void {
    if (this.currentPhase === 'started') {
      this.markRows();
    }
  }

  // Every mark under the root, not just the batch's own rows: a cancelled
  // drop, or a row the item controller marked before it had a session,
  // would otherwise leave one behind.
  end():SelectionItem[]|null {
    if (this.currentPhase === 'ended') {
      return null;
    }

    this.currentPhase = 'ended';
    this.host.rootElement
      .querySelectorAll(`[${draggingAttribute}]`)
      .forEach((element) => element.removeAttribute(draggingAttribute));

    return this.frozenBatch;
  }

  private markRows():void {
    const elements = this.frozenBatch
      ? this.frozenBatchElements()
      : [this.sourceElement];

    elements.forEach((element) => element.setAttribute(draggingAttribute, 'source'));
  }

  private frozenBatchElements():HTMLElement[] {
    const byKey = itemElementsByKey(this.host.rootElement);

    return (this.frozenBatch ?? [])
      .map((item) => byKey.get(selectionKey(item)))
      .filter((element):element is HTMLElement => element !== undefined);
  }
}
