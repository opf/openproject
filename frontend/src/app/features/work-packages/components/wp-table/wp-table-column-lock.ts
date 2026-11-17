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

import { effect, Injector } from '@angular/core';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';

const lockedClass = '-columns-locked';

/**
 * SPIKE (DREAM-1041): lets the browser size the columns with `table-layout: auto`, then pins the
 * measured widths on the `<col>` elements and switches the table to `table-layout: fixed`, so
 * that cell editors cannot resize columns. Measures again after every committed row change and
 * container resize, except while a cell editor is open.
 */
export class WorkPackageTableColumnLock {
  private containerWidth = 0;

  constructor(
    private readonly table:WorkPackageTable,
    private readonly tableElement:HTMLTableElement,
    injector:Injector,
  ) {
    const committed = effect(() => {
      this.table.committedRows();
      this.measureAndLock();
    }, { injector, manualCleanup: true });

    const resized = new ResizeObserver(([entry]) => {
      const width = Math.round(entry.contentRect.width);
      if (width === this.containerWidth) return;
      this.containerWidth = width;
      this.measureAndLock();
    });
    resized.observe(this.table.scrollContainer);

    onDestroySafely(this.table.destroyRef, () => {
      committed.destroy();
      resized.disconnect();
      this.unlock();
    });
  }

  private get columns():HTMLTableColElement[] {
    return Array.from(this.tableElement.querySelectorAll<HTMLTableColElement>(':scope > colgroup > col'));
  }

  private get editorOpen():boolean {
    return this.table.editing.activeTableFields().some(({ handler }) => handler.element?.isConnected);
  }

  private measureAndLock():void {
    if (this.table.destroyed || this.table.hasPendingRender || this.editorOpen) return;

    const headers = Array.from(this.tableElement.tHead?.rows[0]?.cells ?? []);
    const columns = this.columns;
    if (headers.length === 0 || headers.length !== columns.length) return;

    // Unlocking, measuring and locking run in one task, so the auto layout is never painted.
    this.unlock();
    const tableWidth = this.tableElement.getBoundingClientRect().width;
    if (tableWidth === 0) return;
    const widths = headers.map((header) => header.getBoundingClientRect().width);

    columns.forEach((column, index) => { column.style.width = `${widths[index]}px`; });
    this.tableElement.style.width = `${tableWidth}px`;
    this.tableElement.style.tableLayout = 'fixed';
    this.tableElement.classList.add(lockedClass);
  }

  private unlock():void {
    this.tableElement.classList.remove(lockedClass);
    this.tableElement.style.tableLayout = '';
    this.tableElement.style.width = '';
    this.columns.forEach((column) => { column.style.width = ''; });
  }
}
