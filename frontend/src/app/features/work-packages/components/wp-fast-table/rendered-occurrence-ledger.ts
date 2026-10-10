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

import invariant from 'tiny-invariant';
import type { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import type { RelationColumnType } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';

declare const ngDevMode:boolean|undefined;

export type OccurrenceKey = string;

export interface RenderedOccurrence {
  readonly key:OccurrenceKey;
  readonly classIdentifier:string;
  readonly workPackageId:string|null;
  readonly renderType:'primary'|'relations'|'child_relations';
  readonly hidden:boolean;
  element:HTMLTableRowElement|null;
  readonly relation?:{ label:string; columnId:string; relationType:RelationColumnType };
}

export interface DraftOccurrence extends RenderedOccurrence {
  readonly additionalClasses:string[];
  readonly workPackage:WorkPackageResource|null;
}

export interface RenderDraft {
  append(occ:DraftOccurrence):void;
  spliceAfter(targetKey:OccurrenceKey, occ:DraftOccurrence):void;
  readonly occurrences:readonly DraftOccurrence[];
  readonly withTimeline:boolean;
}

export function wpOccurrenceKey(id:string):OccurrenceKey {
  return `wp:${id}`;
}

export function ancestorOccurrenceKey(id:string):OccurrenceKey {
  return `ancestor:${id}`;
}

export function relationOccurrenceKey(type:RelationColumnType, fromId:string, toId:string):OccurrenceKey {
  return `relation:${type}:${fromId}:${toId}`;
}

export function groupOccurrenceKey(index:number, part:'header'|'sums'):OccurrenceKey {
  return `group:${index}:${part}`;
}

export function placeholderOccurrenceKey():OccurrenceKey {
  return 'placeholder';
}

function assertInDevMode(condition:boolean, message:string):void {
  if (typeof ngDevMode !== 'undefined' && ngDevMode) {
    invariant(condition, message);
  }
}

type MutableOccurrence = { -readonly [K in keyof RenderedOccurrence]:RenderedOccurrence[K] };

class Draft implements RenderDraft {
  private readonly items:DraftOccurrence[] = [];

  private readonly keys = new Set<OccurrenceKey>();

  constructor(readonly withTimeline:boolean) {}

  get occurrences():readonly DraftOccurrence[] {
    return this.items;
  }

  append(occ:DraftOccurrence):void {
    this.assertUnregistered(occ.key);
    this.keys.add(occ.key);
    this.items.push(occ);
  }

  spliceAfter(targetKey:OccurrenceKey, occ:DraftOccurrence):void {
    const index = this.items.findIndex((item) => item.key === targetKey);
    assertInDevMode(index !== -1, `Cannot splice after unknown occurrence key: ${targetKey}`);
    this.assertUnregistered(occ.key);
    this.keys.add(occ.key);
    this.items.splice(index + 1, 0, occ);
  }

  private assertUnregistered(key:OccurrenceKey):void {
    assertInDevMode(!this.keys.has(key), `Occurrence key registered twice: ${key}`);
  }
}

export class RenderedOccurrenceLedger {
  private currentGeneration = 0;

  private records:MutableOccurrence[] = [];

  private byKeyIndex = new Map<OccurrenceKey, number>();

  get generation():number {
    return this.currentGeneration;
  }

  get size():number {
    return this.records.length;
  }

  beginRender(withTimeline = false):RenderDraft {
    return new Draft(withTimeline);
  }

  commit(draft:RenderDraft):void {
    this.records = draft.occurrences.map((occ) => ({ ...occ }));
    this.byKeyIndex = new Map(this.records.map((record, index) => [record.key, index]));
    this.currentGeneration += 1;
  }

  setHidden(updates:ReadonlyMap<OccurrenceKey, boolean>):void {
    this.records = this.records.map((record) => {
      const hidden = updates.get(record.key);
      return hidden === undefined ? record : { ...record, hidden };
    });
    this.currentGeneration += 1;
  }

  replaceElement(key:OccurrenceKey, element:HTMLTableRowElement|null):void {
    const record = this.byKey(key);
    assertInDevMode(record !== undefined, `Cannot replace element of unknown occurrence key: ${key}`);
    if (record) {
      record.element = element;
    }
  }

  byKey(key:OccurrenceKey):RenderedOccurrence|undefined {
    const index = this.byKeyIndex.get(key);
    return index === undefined ? undefined : this.records[index];
  }

  byWorkPackageId(id:string):RenderedOccurrence[] {
    return this.records.filter((record) => record.workPackageId === id);
  }

  byElement(element:HTMLTableRowElement):RenderedOccurrence|undefined {
    return this.records.find((record) => record.element === element);
  }

  indexOfKey(key:OccurrenceKey):number {
    return this.byKeyIndex.get(key) ?? -1;
  }

  keyAt(index:number):OccurrenceKey|undefined {
    return this.records[index]?.key;
  }

  snapshot():RenderedWorkPackage[] {
    return this.records.map(({ classIdentifier, workPackageId, hidden }) => ({ classIdentifier, workPackageId, hidden }));
  }
}
