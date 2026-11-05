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
import { navigableCells } from '../handlers/state/keyboard/roving-tabindex';
import { emptyResultsRowKey, headerRowKey, inlineCreateRowKey, totalsRowKey } from '../row-keys';

export type RowRecordKind = TableRowKind|'header';

const edgeRowKeys = {
  header: headerRowKey,
  totals: totalsRowKey,
  inlineCreate: inlineCreateRowKey,
  emptyResults: emptyResultsRowKey,
} as const;

type EdgeRowKind = keyof typeof edgeRowKeys;

const isEdgeRowKind = (kind:RowRecordKind):kind is EdgeRowKind => kind in edgeRowKeys;

export interface RowState {
  readonly kind:RowRecordKind;
  readonly level:number;
  readonly expanded:boolean|null;
  readonly selected:boolean|null;
  /** Kept out of keyboard navigation, and for the totals row also `aria-hidden`. */
  readonly hidden:boolean;
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
    const tableElement = this.table.tbody.closest('table');
    if (!tableElement) return [];
    return Array.from(tableElement.rows).map((row) => this.record(tableElement, row));
  }

  /** The rows of one table section, in document order. */
  public rowsOf(section:HTMLTableSectionElement):RowRecord[] {
    const tableElement = section.closest('table');
    if (!tableElement) return [];
    return Array.from(section.rows).map((row) => this.record(tableElement, row));
  }

  private record(tableElement:HTMLTableElement, row:HTMLTableRowElement):RowRecord {
    const occurrence = this.table.ledger.byElement(row) ?? null;
    const kind = this.kindOf(tableElement, row);
    return {
      key: occurrence?.key ?? this.edgeKeyOf(kind),
      element: row,
      occurrence,
      state: {
        kind,
        level: occurrence?.level ?? 1,
        expanded: this.expansionOf(occurrence, kind),
        selected: occurrence?.workPackageId ? this.wpTableSelection.isSelected(occurrence.workPackageId) : null,
        hidden: this.hiddenOf(row, occurrence, kind),
      },
    };
  }

  private kindOf(tableElement:HTMLTableElement, row:HTMLTableRowElement):RowRecordKind {
    if (row.parentElement === tableElement.tHead) return 'header';
    return classifyRow(this.table, row);
  }

  private edgeKeyOf(kind:RowRecordKind):string|null {
    return isEdgeRowKind(kind) ? edgeRowKeys[kind] : null;
  }

  private hiddenOf(row:HTMLTableRowElement, occurrence:RenderedOccurrence|null, kind:RowRecordKind):boolean {
    if (occurrence) return occurrence.kind === 'placeholder' || occurrence.hidden;
    if (kind === 'totals') return navigableCells(row).length === 0;
    return !isExposedRow(row);
  }

  private expansionOf(occurrence:RenderedOccurrence|null, kind:RowRecordKind):boolean|null {
    if (!occurrence || (kind !== 'workPackage' && kind !== 'groupHeader')) return null;
    return expansionStateOf(this.table, this.wpTableHierarchies, occurrence, kind);
  }
}
