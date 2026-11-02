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

import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import type { RenderedOccurrence } from '../../../rendered-occurrence-ledger';
import type { WorkPackageTable } from '../../../wp-fast-table';
import { NavigableRow, RowKind } from './focus-position';
import { navigableCells } from './roving-tabindex';
import { expansionStateOf, rowKindOf } from '../../../helpers/row-expansion';
import { headerRowOf, totalsRowOf } from '../../../helpers/structural-rows';

export const headerRowKey = 'header';
export const totalsRowKey = 'totals';

export { headerRowOf, totalsRowOf };

function occurrenceRow(
  table:WorkPackageTable,
  hierarchies:WorkPackageViewHierarchiesService,
  occurrence:RenderedOccurrence,
):NavigableRow|null {
  const kind = rowKindOf(occurrence);
  if (kind === null || !occurrence.element) {
    return null;
  }

  const row:NavigableRow = {
    key: occurrence.key,
    kind,
    hidden: occurrence.hidden,
    cellCount: navigableCells(occurrence.element).length,
    expanded: expansionStateOf(table, hierarchies, occurrence, kind),
  };

  return occurrence.groupIdentifier === undefined ? row : { ...row, groupIdentifier: occurrence.groupIdentifier };
}

function edgeRow(key:string, kind:RowKind, element:HTMLTableRowElement|null):NavigableRow[] {
  if (!element) {
    return [];
  }

  const cellCount = navigableCells(element).length;
  return [{
    key, kind, hidden: kind === 'totals' && cellCount === 0, cellCount, expanded: null,
  }];
}

/** The rows keyboard navigation walks, in visual order: header, rendered occurrences, totals. */
export function buildNavigableRows(table:WorkPackageTable):NavigableRow[] {
  const { ledger } = table;
  const hierarchies = table.injector.get(WorkPackageViewHierarchiesService);
  const body = Array.from({ length: ledger.size }, (_, index) => ledger.byKey(ledger.keyAt(index)!)!)
    .map((occurrence) => occurrenceRow(table, hierarchies, occurrence))
    .filter((row):row is NavigableRow => row !== null);

  return [
    ...edgeRow(headerRowKey, 'header', headerRowOf(table)),
    ...body,
    ...edgeRow(totalsRowKey, 'totals', totalsRowOf(table)),
  ];
}
