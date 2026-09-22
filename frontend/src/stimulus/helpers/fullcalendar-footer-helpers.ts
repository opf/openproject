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

export const FOOTER_TOTALS_CLASS_NAME = 'fc-timegrid-footer-totals';

export type FooterCellContent = (date:string) => string|Node;

// FullCalendar's timegrid has no footer row, so one is appended to the scrollgrid by hand.
// The row mirrors the markup of the column header so that it inherits its column widths.
// Call this after the view has rendered and whenever the events change.

export function renderFooterTotals(root:ParentNode, contentForDate:FooterCellContent):void {
  const scrollGridBody = root.querySelector('.fc-timegrid .fc-scrollgrid tbody');

  if (!scrollGridBody) {
    return;
  }

  root.querySelector(`.${FOOTER_TOTALS_CLASS_NAME}`)?.remove();

  const days = Array
    .from(root.querySelectorAll('.fc-timegrid-cols .fc-day'))
    .map((day) => day.getAttribute('data-date'))
    .filter((date):date is string => !!date);

  scrollGridBody.appendChild(buildFooterRow(root, days, contentForDate));
}

function buildFooterRow(root:ParentNode, days:string[], contentForDate:FooterCellContent):HTMLTableRowElement {
  const row = document.createElement('tr');
  row.setAttribute('role', 'presentation');
  row.className = `fc-scrollgrid-section ${FOOTER_TOTALS_CLASS_NAME}`;

  const cell = document.createElement('td');
  cell.setAttribute('role', 'presentation');

  const scrollerHarness = document.createElement('div');
  scrollerHarness.className = 'fc-scroller-harness';

  const scroller = document.createElement('div');
  scroller.className = 'fc-scroller';
  scroller.style.overflow = 'hidden scroll';

  const table = document.createElement('table');
  table.setAttribute('role', 'presentation');
  table.className = 'fc-col-footer';

  const colgroup = document.createElement('colgroup');
  const col = document.createElement('col');
  const headerCol = root.querySelector<HTMLTableColElement>('.fc-scrollgrid-section-header .fc-col-header col');
  if (headerCol) {
    col.style.width = headerCol.style.width;
  }
  colgroup.appendChild(col);

  const body = document.createElement('tbody');
  body.setAttribute('role', 'presentation');

  const bodyRow = document.createElement('tr');
  bodyRow.setAttribute('role', 'row');
  bodyRow.appendChild(buildAxisCell());

  days.forEach((day) => {
    bodyRow.appendChild(buildDayCell(contentForDate(day)));
  });

  body.appendChild(bodyRow);
  table.appendChild(colgroup);
  table.appendChild(body);
  scroller.appendChild(table);
  scrollerHarness.appendChild(scroller);
  cell.appendChild(scrollerHarness);
  row.appendChild(cell);

  return row;
}

function buildAxisCell():HTMLTableCellElement {
  const axis = document.createElement('th');
  axis.setAttribute('aria-hidden', 'true');
  axis.className = 'fc-timegrid-axis';

  const frame = document.createElement('div');
  frame.className = 'fc-timegrid-axis-frame';
  axis.appendChild(frame);

  return axis;
}

function buildDayCell(content:string|Node):HTMLTableCellElement {
  const cell = document.createElement('th');
  cell.setAttribute('role', 'columnfooter');
  cell.className = 'fc-col-footer-cell fc-day';

  const inner = document.createElement('div');
  inner.className = 'fc-scrollgrid-sync-inner';

  if (typeof content === 'string') {
    inner.textContent = content;
  } else {
    inner.appendChild(content);
  }
  cell.appendChild(inner);

  return cell;
}
