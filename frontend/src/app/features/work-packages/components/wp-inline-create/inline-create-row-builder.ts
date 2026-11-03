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
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { tdClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/cell-builder';
import { internalContextMenuColumn } from 'core-app/features/work-packages/components/wp-fast-table/builders/internal-sort-columns';
import { EditForm } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { WorkPackageTable } from '../wp-fast-table/wp-fast-table';
import { rowId } from '../wp-fast-table/helpers/wp-table-row-helpers';
import {
  commonRowClassName,
  SingleRowBuilder,
  tableRowClassName,
} from '../wp-fast-table/builders/rows/single-row-builder';

export const inlineCreateRowClassName = 'wp-inline-create-row';
export const inlineCreateCancelClassName = 'wp-table--cancel-create-link';
const cancelLinkHostClassName = 'wp-table--cancel-create-host';

export class InlineCreateRowBuilder extends SingleRowBuilder {
  // Injections
  @LazyInject() public states:States;

  @LazyInject() public wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() public wpTableColumns:WorkPackageViewColumnsService;

  @LazyInject() public I18n:I18nService;

  protected text:{ cancelButton:string };

  constructor(public readonly injector:Injector,
    workPackageTable:WorkPackageTable) {
    super(injector, workPackageTable);

    this.text = {
      cancelButton: this.I18n.t('js.button_cancel'),
    };
  }

  protected override get rowHeaderColumn():'subject'|'id'|null {
    return null;
  }

  public buildCell(workPackage:WorkPackageResource, column:QueryColumn):HTMLTableCellElement|null {
    switch (column.id) {
      case internalContextMenuColumn.id:
        return this.buildCancelButton();
      default:
        return super.buildCell(workPackage, column);
    }
  }

  public buildNew(workPackage:WorkPackageResource, _form:EditForm):[HTMLElement, boolean] {
    // Get any existing edit state for this work package
    const [row, hidden] = this.buildEmpty(workPackage);

    return [row, hidden];
  }

  public buildEmpty(workPackage:WorkPackageResource):[HTMLTableRowElement, boolean] {
    const [row, hidden] = super.buildEmpty(workPackage);
    this.placeCancelLink(row);

    return [row, hidden];
  }

  public refreshRow(workPackage:WorkPackageResource, row:HTMLTableRowElement):HTMLTableRowElement {
    const refreshed = super.refreshRow(workPackage, row);
    this.placeCancelLink(refreshed);

    return refreshed;
  }

  private placeCancelLink(row:HTMLTableRowElement):void {
    const host = this.cancelLinkHost(row);

    row.querySelectorAll<HTMLTableCellElement>(`td.${cancelLinkHostClassName}`).forEach((cell) => {
      if (cell !== host) {
        cell.classList.remove(cancelLinkHostClassName);
        cell.querySelector(`.${inlineCreateCancelClassName}`)?.remove();
      }
    });
    if (host) {
      this.appendCancelLink(host);
    }
  }

  private cancelLinkHost(row:HTMLTableRowElement):HTMLTableCellElement|null {
    if (this.augmentedColumns.includes(internalContextMenuColumn)) {
      return null;
    }

    const lastColumn = this.augmentedColumns.at(-1)!;
    return row.querySelector<HTMLTableCellElement>(`td.${lastColumn.id}`);
  }

  private appendCancelLink(cell:HTMLTableCellElement) {
    if (cell.querySelector(`.${inlineCreateCancelClassName}`)) {
      return;
    }

    cell.classList.add(cancelLinkHostClassName);
    cell.insertAdjacentHTML('beforeend', this.cancelLinkHtml());
  }

  /**
   * Create an empty unattached row element for the given work package
   * @param workPackage
   * @returns {any}
   */
  public createEmptyRow(workPackage:WorkPackageResource) {
    const identifier = this.classIdentifier(workPackage);
    const tr = document.createElement('tr');
    tr.id = rowId(workPackage.id!);
    tr.dataset.workPackageId = workPackage.id!;
    tr.dataset.classIdentifier = identifier;
    tr.classList.add(
      inlineCreateRowClassName, commonRowClassName, tableRowClassName, 'issue',
      identifier,
      `${identifier}-table`,
    );

    return tr;
  }

  protected buildCancelButton() {
    const td = document.createElement('td');
    td.classList.add(tdClassName, 'wp-table--cancel-create-td');

    td.innerHTML = this.cancelLinkHtml();

    return td;
  }

  private cancelLinkHtml():string {
    return `
    <a
       href="#"
       class="${inlineCreateCancelClassName} icon icon-cancel"
       aria-label="${this.text.cancelButton}">
    </a>
   `;
  }
}
