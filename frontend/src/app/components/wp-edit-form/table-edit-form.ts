// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {Injector} from '@angular/core';
import {Subscription} from 'rxjs';
import {States} from 'core-components/states.service';
import {IFieldSchema} from "core-app/modules/fields/field.base";

import {EditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import {WorkPackageViewColumnsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import {FocusHelperService} from "core-app/modules/common/focus/focus-helper";
import {EditingPortalService} from "core-app/modules/fields/edit/editing-portal/editing-portal-service";
import {CellBuilder, editCellContainer, tdClassName} from "core-components/wp-fast-table/builders/cell-builder";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {EditForm} from "core-app/modules/fields/edit/edit-form/edit-form";
import {editModeClassName} from "core-app/modules/fields/edit/edit-field.component";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export const activeFieldContainerClassName = 'inline-edit--active-field';
export const activeFieldClassName = 'inline-edit--field';

export class TableEditForm extends EditForm<WorkPackageResource> {
  @InjectField() public wpTableColumns:WorkPackageViewColumnsService;
  @InjectField() public wpCacheService:WorkPackageCacheService;
  @InjectField() public states:States;
  @InjectField() public FocusHelper:FocusHelperService;
  @InjectField() public editingPortalService:EditingPortalService;

  // Use cell builder to reset edit fields
  private cellBuilder = new CellBuilder(this.injector);

  // Subscription
  private resourceSubscription:Subscription = this.wpCacheService
    .requireAndStream(this.workPackageId)
    .subscribe((wp) => this.resource = wp);

  constructor(public injector:Injector,
              public table:WorkPackageTable,
              public workPackageId:string,
              public classIdentifier:string) {
    super(injector);
  }

  destroy() {
    this.resourceSubscription.unsubscribe();
  }

  public findContainer(fieldName:string):JQuery {
    return this.rowContainer.find(`.${tdClassName}.${fieldName} .${editCellContainer}`).first();
  }

  public findCell(fieldName:string) {
    return this.rowContainer.find(`.${tdClassName}.${fieldName}`).first();
  }

  public activateField(form:EditForm, schema:IFieldSchema, fieldName:string, errors:string[]):Promise<EditFieldHandler> {
    return this.waitForContainer(fieldName)
      .then((cell) => {

        // Forcibly set the width since the edit field may otherwise
        // be given more width. Thereby preserve a minimum width of 150.
        // To avoid flickering content, the padding is removed, too.
        const td = this.findCell(fieldName);
        td.addClass(editModeClassName);
        let width = parseInt(td.css('width'));
        width = width > 150 ? width - 10 : 150;
        td.css('max-width', width + 'px');
        td.css('width', width + 'px');

        return this.editingPortalService.create(
          cell,
          this.injector,
          form,
          schema,
          fieldName,
          errors
        );
      });
  }

  public reset(fieldName:string, focus?:boolean) {
    const cell = this.findContainer(fieldName);
    const td = this.findCell(fieldName);

    if (cell.length) {
      this.findCell(fieldName).css('width', '');
      this.findCell(fieldName).css('max-width', '');
      this.cellBuilder.refresh(cell[0], this.resource, fieldName);
      td.removeClass(editModeClassName);

      if (focus) {
        this.FocusHelper.focusElement(cell);
      }
    }
  }

  public requireVisible(fieldName:string):Promise<any> {
    this.wpTableColumns.addColumn(fieldName);
    return this.waitForContainer(fieldName);
  }

  protected focusOnFirstError():void {
    // Focus the first field that is erroneous
    jQuery(this.table.tableAndTimelineContainer)
      .find(`.${activeFieldContainerClassName}.-error .${activeFieldClassName}`)
      .first()
      .trigger('focus');
  }

  // Ensure the given field is visible.
  // We may want to look into MutationObserver if we need this in several places.
  private waitForContainer(fieldName:string):Promise<HTMLElement> {
    return new Promise<HTMLElement>((resolve, reject) => {
      const interval = setInterval(() => {
        const container = this.findContainer(fieldName);

        if (container.length > 0) {
          clearInterval(interval);
          resolve(container[0]);
        }
      }, 100);
    });
  }

  private get rowContainer() {
    return jQuery(this.table.tableAndTimelineContainer).find(`.${this.classIdentifier}-table`);
  }

}
