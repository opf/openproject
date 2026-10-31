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

import { Injector } from '@angular/core';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import type { RenderedOccurrence } from '../rendered-occurrence-ledger';
import type { WorkPackageTable } from '../wp-fast-table';
import { classifyRow, isExposedRow, type TableRowKind } from '../helpers/structural-rows';
import { expansionStateOf } from '../helpers/row-expansion';

export type RowRecordKind = Exclude<TableRowKind, 'create'|'empty'>|'header'|'inlineCreate'|'emptyResults';

export const edgeRowKeys = {
  header: 'header',
  totals: 'totals',
  inlineCreate: 'inlineCreate',
  emptyResults: 'emptyResults',
} as const;

export interface RowState {
  readonly kind:RowRecordKind;
  readonly level:number;
  readonly expanded:boolean|null;
  readonly exposed:boolean;
  readonly selected:boolean|null;
}

export interface RowRecord {
  readonly key:string|null;
  readonly element:HTMLTableRowElement;
  readonly occurrence:RenderedOccurrence|null;
  readonly state:RowState;
}

export class RowClassifier {
  @LazyInject() private readonly wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() private readonly wpTableHierarchies:WorkPackageViewHierarchiesService;

  public readonly injector:Injector = this.table.injector;

  constructor(private readonly table:WorkPackageTable) {}

  /** Every row of the table, in document order, across all its sections. */
  public rows():RowRecord[] {
    const element = this.table.tbody.closest('table');
    if (!element) return [];
    return Array.from(element.rows).map((row) => this.record(element, row));
  }

  private record(table:HTMLTableElement, row:HTMLTableRowElement):RowRecord {
    const occurrence = this.table.ledger.byElement(row) ?? null;
    const kind = this.kindOf(table, row);
    return {
      key: occurrence?.key ?? this.edgeKeyOf(kind),
      element: row,
      occurrence,
      state: {
        kind,
        level: occurrence?.level ?? 1,
        expanded: this.expansionOf(occurrence, kind),
        exposed: occurrence ? !occurrence.hidden : isExposedRow(row),
        selected: occurrence?.workPackageId ? this.wpTableSelection.isSelected(occurrence.workPackageId) : null,
      },
    };
  }

  private kindOf(table:HTMLTableElement, row:HTMLTableRowElement):RowRecordKind {
    if (row.parentElement === table.tHead) return 'header';
    const kind = classifyRow(this.table, row);
    if (kind === 'create') return 'inlineCreate';
    if (kind === 'empty') return 'emptyResults';
    return kind;
  }

  private edgeKeyOf(kind:RowRecordKind):string|null {
    return kind in edgeRowKeys ? edgeRowKeys[kind as keyof typeof edgeRowKeys] : null;
  }

  private expansionOf(occurrence:RenderedOccurrence|null, kind:RowRecordKind):boolean|null {
    if (!occurrence || (kind !== 'workPackage' && kind !== 'groupHeader')) return null;
    return expansionStateOf(this.table, this.wpTableHierarchies, occurrence, kind);
  }
}
