import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {States} from '../states.service';
import {
  commonRowClassName,
  SingleRowBuilder,
  tableRowClassName
} from '../wp-fast-table/builders/rows/single-row-builder';
import {rowId} from '../wp-fast-table/helpers/wp-table-row-helpers';
import {WorkPackageTable} from '../wp-fast-table/wp-fast-table';
import {WorkPackageViewSelectionService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import {WorkPackageViewColumnsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import {QueryColumn} from "core-components/wp-query/query-column";
import {tdClassName} from "core-components/wp-fast-table/builders/cell-builder";
import {internalContextMenuColumn} from "core-components/wp-fast-table/builders/internal-sort-columns";
import {EditForm} from "core-app/modules/fields/edit/edit-form/edit-form";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export const inlineCreateRowClassName = 'wp-inline-create-row';
export const inlineCreateCancelClassName = 'wp-table--cancel-create-link';

export class InlineCreateRowBuilder extends SingleRowBuilder {

  // Injections
  @InjectField() public states:States;
  @InjectField() public wpTableSelection:WorkPackageViewSelectionService;
  @InjectField() public wpTableColumns:WorkPackageViewColumnsService;
  @InjectField() public I18n:I18nService;

  protected text:{ cancelButton:string };

  constructor(public readonly injector:Injector,
              workPackageTable:WorkPackageTable) {

    super(injector, workPackageTable);

    this.text = {
      cancelButton: this.I18n.t('js.button_cancel')
    };
  }

  public buildCell(workPackage:WorkPackageResource, column:QueryColumn):HTMLElement|null {
    switch (column.id) {
      case internalContextMenuColumn.id:
        return this.buildCancelButton();
      default:
        return super.buildCell(workPackage, column);
    }
  }

  public buildNew(workPackage:WorkPackageResource, form:EditForm):[HTMLElement, boolean] {
    // Get any existing edit state for this work package
    const [row, hidden] = this.buildEmpty(workPackage);


    return [row, hidden];
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
    tr.dataset['workPackageId'] = workPackage.id!;
    tr.dataset['classIdentifier'] = identifier;
    tr.classList.add(
      inlineCreateRowClassName, commonRowClassName, tableRowClassName, 'issue',
      identifier,
      `${identifier}-table`
    );

    return tr;
  }

  protected buildCancelButton() {
    const td = document.createElement('td');
    td.classList.add(tdClassName, 'wp-table--cancel-create-td');

    td.innerHTML = `
    <a
       href="#"
       class="${inlineCreateCancelClassName} icon icon-cancel"
       aria-label="${this.text.cancelButton}">
    </a>
   `;

    return td;
  }
}
