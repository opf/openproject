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

/**
 * One selectable item's identity.
 *
 * Type as well as id, because ids are unique per source table rather than per
 * root: a section and a custom field can both be id 5, and a nested list puts
 * them under one root. Keying on the id alone would let one paint the other.
 */
export interface SelectionItem {
  type:string;
  id:string;
}

/** An opaque key for one item. Build it with {@link selectionKey}. */
export type SelectionKey = string;

// U+001F (unit separator) cannot appear in an HTML attribute value that
// reached us through the DOM, so no type or id can forge a collision. Written
// as an escape rather than a literal control character in source.
const KEY_SEPARATOR = '\u001F';

export function selectionKey({ type, id }:SelectionItem):SelectionKey {
  return `${type}${KEY_SEPARATOR}${id}`;
}

/**
 * The item from which a contiguous batch range is measured.
 *
 * `listKey` is opaque here: the model records which list a range may span
 * without learning what a list is. Its holder decides how to derive it, and
 * rebinds it through {@link BatchSelection#rebindAnchor} when the item moves.
 */
export interface SelectionAnchor extends SelectionItem {
  listKey:string;
}

/**
 * Visual order belongs to the live document. Callers resolve ranges and
 * determine whether their members may belong to the same batch.
 */
export class BatchSelection {
  private selectedItems = new Map<SelectionKey, SelectionItem>();
  private selectionAnchor:SelectionAnchor|null = null;
  private rangeBaseline:Map<SelectionKey, SelectionItem>|null = null;

  // Keys, for membership tests and presentation matching.
  get keys():ReadonlySet<SelectionKey> {
    return new Set(this.selectedItems.keys());
  }

  // The pairs themselves, for callers that need the type back.
  items():SelectionItem[] {
    return [...this.selectedItems.values()];
  }

  get anchor():SelectionAnchor|null {
    return this.selectionAnchor;
  }

  get size():number {
    return this.selectedItems.size;
  }

  has(item:SelectionItem):boolean {
    return this.selectedItems.has(selectionKey(item));
  }

  replace(item:SelectionItem, listKey:string):void {
    this.rangeBaseline = null;
    this.selectedItems = new Map([[selectionKey(item), item]]);
    this.selectionAnchor = { ...item, listKey };
  }

  // Re-bases the anchor even when the toggle deselects: the user's last
  // touched card is where they expect the next range to start from.
  toggle(item:SelectionItem, listKey:string):void {
    this.rangeBaseline = null;
    const key = selectionKey(item);

    if (this.selectedItems.has(key)) {
      this.selectedItems.delete(key);
    } else {
      this.selectedItems.set(key, item);
    }

    this.selectionAnchor = { ...item, listKey };
  }

  // The anchor stays put so repeated Shift gestures resize one range rather
  // than walking it across the list.
  range(rangeItems:readonly SelectionItem[]):void {
    this.rangeBaseline ??= new Map(this.selectedItems);
    this.selectedItems = new Map(this.rangeBaseline);
    for (const item of rangeItems) {
      this.selectedItems.set(selectionKey(item), item);
    }
  }

  selectAll(items:readonly SelectionItem[], anchor:SelectionAnchor|null):void {
    this.rangeBaseline = new Map();
    this.selectedItems = new Map(items.map((item) => [selectionKey(item), item]));
    this.selectionAnchor = anchor;
  }

  clear():void {
    this.rangeBaseline = null;
    this.selectedItems = new Map();
    this.selectionAnchor = null;
  }

  clearAnchor():void {
    this.selectionAnchor = null;
    this.rangeBaseline = null;
  }

  /**
   * Points the existing anchor at a different list.
   *
   * A card can be moved to another list while remaining the anchor — a
   * cross-list drag does exactly that. The caller re-derives the key from the
   * live document and hands it back.
   */
  rebindAnchor(listKey:string):void {
    if (this.selectionAnchor && this.selectionAnchor.listKey !== listKey) {
      this.rangeBaseline = null;
      this.selectionAnchor = { ...this.selectionAnchor, listKey };
    }
  }

  /**
   * Drops members and an anchor that no longer exist in the document.
   *
   * `liveKeys` is keyed the same way membership is, so an id that survives
   * under a *different* type does not keep a stale member alive.
   *
   * @return whether membership or the anchor changed, for a caller that can
   *   skip redundant work when nothing did.
   */
  prune(liveKeys:ReadonlySet<SelectionKey>):boolean {
    let changed = false;

    for (const key of [...this.selectedItems.keys()]) {
      if (!liveKeys.has(key)) {
        this.selectedItems.delete(key);
        this.rangeBaseline?.delete(key);
        changed = true;
      }
    }

    if (this.selectionAnchor && !liveKeys.has(selectionKey(this.selectionAnchor))) {
      this.selectionAnchor = null;
      this.rangeBaseline = null;
      changed = true;
    }

    return changed;
  }
}
