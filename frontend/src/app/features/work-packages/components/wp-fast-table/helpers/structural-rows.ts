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

import type { WorkPackageTable } from '../wp-fast-table';

const totalsRowSelector = 'tr.wp-table--sums-row';

/** The `thead` row of the table, when rendered. */
export function headerRowOf(table:WorkPackageTable):HTMLTableRowElement|null {
  return table.tbody.closest('table')?.querySelector<HTMLTableRowElement>('thead tr') ?? null;
}

/** The totals row below the results; group sums rows inside the results body do not qualify. */
export function isTotalsRow(table:WorkPackageTable, row:HTMLTableRowElement):boolean {
  return row.matches(totalsRowSelector) && !table.tbody.contains(row);
}

/** The totals row below the results, when rendered. */
export function totalsRowOf(table:WorkPackageTable):HTMLTableRowElement|null {
  const rows = table.tbody.closest('table')?.querySelectorAll<HTMLTableRowElement>(totalsRowSelector) ?? [];
  return Array.from(rows).find((row) => isTotalsRow(table, row)) ?? null;
}

export function isInlineCreateRow(row:HTMLTableRowElement):boolean {
  return row.parentElement?.hasAttribute('wpInlineCreate') === true;
}

export function isEmptyResultsRow(row:HTMLTableRowElement):boolean {
  return row.parentElement?.classList.contains('work-package--empty-tbody') === true;
}

/** A row assistive technology can reach: neither hidden itself nor inside a hidden section. */
export function isExposedRow(row:HTMLTableRowElement):boolean {
  return !row.hidden
    && row.getAttribute('aria-hidden') !== 'true'
    && row.parentElement?.getAttribute('aria-hidden') !== 'true';
}
