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
import { placeholderOccurrenceKey, type RenderedOccurrence } from '../rendered-occurrence-ledger';
import { inlineCreateSelector } from '../handlers/state/keyboard/roving-tabindex';

const totalsRowSelector = 'tr.wp-table--sums-row';

export type OccurrenceRowKind = 'workPackage'|'groupHeader'|'sums'|'placeholder'|'foreign';

/** Every body or trailing row of the table; `foreign` is a row no producer declared. */
export type TableRowKind = OccurrenceRowKind|'totals'|'create'|'empty'|'unexposed';

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
  return row.parentElement?.matches(inlineCreateSelector) === true;
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

export function occurrenceRowKind(occurrence:RenderedOccurrence):OccurrenceRowKind {
  if (occurrence.key === placeholderOccurrenceKey()) return 'placeholder';
  if (occurrence.key.startsWith('group:')) return occurrence.key.endsWith(':sums') ? 'sums' : 'groupHeader';
  return occurrence.workPackageId === null ? 'foreign' : 'workPackage';
}

/** Rendered occurrences keep their kind even while hidden; other rows count only while exposed. */
export function classifyRow(table:WorkPackageTable, row:HTMLTableRowElement):TableRowKind {
  const occurrence = table.ledger.byElement(row);
  if (occurrence) return occurrenceRowKind(occurrence);
  if (!isExposedRow(row)) return 'unexposed';
  if (isEmptyResultsRow(row)) return 'empty';
  if (isTotalsRow(table, row)) return 'totals';
  if (isInlineCreateRow(row)) return 'create';
  return 'foreign';
}
