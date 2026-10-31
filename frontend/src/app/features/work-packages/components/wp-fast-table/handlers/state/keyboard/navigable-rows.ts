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

import type { WorkPackageTable } from '../../../wp-fast-table';
import type { RowRecord } from '../../../semantics/row-classifier';
import { NavigableRow, RowKind } from './focus-position';
import { navigableCells } from './roving-tabindex';
import { headerRowOf, totalsRowOf } from '../../../helpers/structural-rows';

export const headerRowKey = 'header';
export const totalsRowKey = 'totals';

export { headerRowOf, totalsRowOf };

const navigableKinds:ReadonlySet<string> = new Set<RowKind>(['header', 'workPackage', 'groupHeader', 'sums', 'totals']);

function isNavigableKind(kind:string):kind is RowKind {
  return navigableKinds.has(kind);
}

function navigableRow({ element, occurrence, state }:RowRecord, key:string, kind:RowKind):NavigableRow {
  const cellCount = navigableCells(element).length;
  const row:NavigableRow = {
    key,
    kind,
    hidden: occurrence ? occurrence.hidden : kind === 'totals' && cellCount === 0,
    cellCount,
    expanded: state.expanded,
  };
  return occurrence?.groupIdentifier === undefined ? row : { ...row, groupIdentifier: occurrence.groupIdentifier };
}

/** The rows keyboard navigation walks, in visual order: header, rendered occurrences, totals. */
export function buildNavigableRows(table:WorkPackageTable):NavigableRow[] {
  return table.rows.rows().flatMap((record) => {
    const { key, state: { kind } } = record;
    return key !== null && isNavigableKind(kind) ? [navigableRow(record, key, kind)] : [];
  });
}
