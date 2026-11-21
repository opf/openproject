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

const tableSelector = 'table.keyboard-accessible-list';
const sumsRowClassName = 'wp-table--sums-row';
const rowSelector = `tbody.work-package--results-tbody > tr, tbody > tr.${sumsRowClassName}`;

function nearestTable(active:Element|null, offset:number):Element|null {
  const tables = Array.from(document.querySelectorAll(tableSelector)).filter((table) => table.checkVisibility());
  const side = offset > 0 ? Node.DOCUMENT_POSITION_FOLLOWING : Node.DOCUMENT_POSITION_PRECEDING;
  const onSide = active ? tables.filter((table) => (active.compareDocumentPosition(table) & side) !== 0) : [];

  return offset > 0
    ? onSide[0] ?? tables[0] ?? null
    : onSide.at(-1) ?? tables.at(-1) ?? null;
}

export function focusWorkPackageTableRowOffset(offset:1|-1):void {
  const active = document.activeElement;
  const enclosing = active?.closest(tableSelector) ?? null;
  const table = enclosing ?? nearestTable(active, offset);
  if (!table) {
    return;
  }

  const rows = Array.from(table.querySelectorAll<HTMLTableRowElement>(rowSelector))
    .filter((row) => row.checkVisibility());
  const current = enclosing ? active?.closest('tr') ?? null : null;
  const index = current ? rows.indexOf(current) : -1;
  const start = !enclosing && offset < 0 ? rows.length : index;
  for (let next = start + offset; next >= 0 && next < rows.length; next += offset) {
    if (!rows[next].classList.contains(sumsRowClassName)) {
      rows[next].focus();
      return;
    }
  }
}
