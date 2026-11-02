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

import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageTableConfiguration } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { activeFieldContainerClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import {
  internalBaselineColumn,
  internalContextMenuColumn,
  internalSortColumn,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/internal-sort-columns';

export const navigableCellClassName = 'wp-table--navigable-cell';
export const inlineCreateSelector = 'tbody[wpInlineCreate]';

const nativeTabStopSelector = 'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])';

/** Whether `node` is in the grid: inside `root` but not in the inline-create body. */
export function insideGrid(root:HTMLElement, node:Node|null):boolean {
  if (!node || !root.contains(node)) {
    return false;
  }

  const element = node instanceof Element ? node : node.parentElement;
  return !element?.closest(inlineCreateSelector);
}

export function keyboardNavigationEnabled(configuration?:WorkPackageTableConfiguration):boolean {
  return configuration?.keyboardNavigationEnabled ?? false;
}

export function isNavigableColumn(column:QueryColumn, configuration:WorkPackageTableConfiguration):boolean {
  switch (column.id) {
    case internalSortColumn.id:
    case internalBaselineColumn.id:
      return false;
    case internalContextMenuColumn.id:
      return configuration.actionsColumnEnabled || configuration.columnMenuEnabled;
    default:
      return true;
  }
}

/**
 * Makes `focused` the table's only Tab stop: it gets `tabindex="0"`, every
 * other row, navigable cell and native Tab stop under `root` gets `tabindex="-1"`.
 */
export function paintRovingTabindex(root:HTMLElement, focused:HTMLElement|null):void {
  root
    .querySelectorAll<HTMLElement>(`tr, .${navigableCellClassName}`)
    .forEach((element) => {
      if (!element.closest(inlineCreateSelector)) {
        element.setAttribute('tabindex', element === focused ? '0' : '-1');
      }
    });

  root
    .querySelectorAll<HTMLElement>(nativeTabStopSelector)
    .forEach((element) => {
      if (element !== focused && !element.closest(inlineCreateSelector) && !element.closest(`.${activeFieldContainerClassName}`)) {
        element.setAttribute('tabindex', '-1');
      }
    });
}

/** The cells of `row` that keyboard navigation can focus, in column order. */
export function navigableCells(row:HTMLTableRowElement):HTMLTableCellElement[] {
  return Array.from(row.cells).filter((cell) => cell.classList.contains(navigableCellClassName));
}
