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

const ariaRowIndexAttribute = 'aria-rowindex';

export function reindexAriaRowsAfter(containers:Element[], mutate:() => void):void {
  const starts = captureAriaRowIndexStarts(containers);

  mutate();
  renumberAriaRowIndices(starts);
}

function ariaIndexedRows(container:Element):Element[] {
  return Array.from(container.children)
    .filter((row) => Number.isInteger(Number(row.getAttribute(ariaRowIndexAttribute) ?? NaN)));
}

function captureAriaRowIndexStarts(containers:Element[]):Map<Element, number> {
  const starts = new Map<Element, number>();

  for (const container of new Set(containers)) {
    const indices = ariaIndexedRows(container).map((row) => Number(row.getAttribute(ariaRowIndexAttribute)));

    if (indices.length > 0) {
      starts.set(container, Math.min(...indices));
    }
  }

  return starts;
}

function renumberAriaRowIndices(starts:Map<Element, number>):void {
  starts.forEach((start, container) => {
    ariaIndexedRows(container).forEach((row, offset) => {
      row.setAttribute(ariaRowIndexAttribute, String(start + offset));
    });
  });
}
