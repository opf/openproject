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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { Subscription } from 'rxjs';
import { States } from 'core-app/core/states/states.service';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';

import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import {
  WorkPackageViewColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { EditingPortalService } from 'core-app/shared/components/fields/edit/editing-portal/editing-portal-service';
import {
  CellBuilder,
  tdClassName,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/cell-builder';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { EditForm } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { editModeClassName } from 'core-app/shared/components/fields/edit/edit-field.component';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { editFieldContainerClass } from 'core-app/shared/components/fields/display/display-field-renderer';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';

export const activeFieldContainerClassName = 'inline-edit--active-field';
export const activeFieldClassName = 'inline-edit--field';

export class TableEditForm extends EditForm<WorkPackageResource> {
  @LazyInject() public wpTableColumns:WorkPackageViewColumnsService;

  @LazyInject() public apiV3Service!:ApiV3Service;

  @LazyInject() public states:States;

  @LazyInject() public FocusHelper:FocusHelperService;

  @LazyInject() public editingPortalService:EditingPortalService;

  @LazyInject() wpListService:WorkPackagesListService;

  // Use cell builder to reset edit fields
  private cellBuilder = new CellBuilder(this.injector);

  // Subscription
  private resourceSubscription:Subscription = this
    .apiV3Service
    .work_packages
    .id(this.workPackageId)
    .requireAndStream()
    .subscribe((wp) => this.resource = wp);

  constructor(
    public injector:Injector,
    public table:WorkPackageTable,
    public workPackageId:string,
    public classIdentifier:string,
  ) {
    super(injector);
  }

  destroy() {
    _.each(this.activeFields, (field) => {
      field.deactivate(false);
    });
    this.resourceSubscription.unsubscribe();
  }

  public findContainer(fieldName:string) {
    return this.rowContainer?.querySelector<HTMLElement>(`.${tdClassName}.${fieldName} .${editFieldContainerClass}`);
  }

  public findCell(fieldName:string) {
    return this.rowContainer?.querySelector<HTMLTableCellElement>(`.${tdClassName}.${fieldName}`);
  }

  public activateField(form:EditForm, schema:IFieldSchema, fieldName:string, errors:string[]):Promise<EditFieldHandler> {
    return this.waitForContainer(fieldName)
      .then((cell) => {
        // Forcibly set the width since the edit field may otherwise
        // be given more width. Thereby preserve a minimum width of 150.
        // To avoid flickering content, the padding is removed, too.
        const td = this.findCell(fieldName)!;
        td.classList.add(editModeClassName);
        let width = td.offsetWidth;
        width = width > 150 ? width - 10 : 150;
        td.style.maxWidth = `${width}px`;
        td.style.width = `${width}px`;

        return this.editingPortalService.create(
          cell,
          this.injector,
          form,
          schema,
          fieldName,
          errors,
        );
      });
  }

  public reset(fieldName:string, focus?:boolean) {
    const cell = this.findContainer(fieldName);
    const td = this.findCell(fieldName)!;

    if (cell) {
      td.style.width = '';
      td.style.maxWidth = '';
      this.cellBuilder.refresh(cell, this.resource, fieldName);
      td.classList.remove(editModeClassName);

      if (focus) {
        this.FocusHelper.focus(cell);
      }
    }
  }

  public requireVisible(fieldName:string):Promise<any> {
    // Ensure the query form is loaded before trying to set fields
    // as we require new columns to be present
    return this.wpListService
      .conditionallyLoadForm()
      .then(() => {
        this.wpTableColumns.addColumn(fieldName);
        return this.waitForContainer(fieldName);
      });
  }

  protected focusOnFirstError():void {
    // Focus the first field that is erroneous
    this.table.tableAndTimelineContainer
      ?.querySelector<HTMLElement>(`.${activeFieldContainerClassName}.-error .${activeFieldClassName}`)
      ?.focus();
  }

  /**
   * Load the resource form to get the current field schema with all
   * values loaded.
   * @param fieldName
   */
  protected loadFieldSchema(fieldName:string, noWarnings = false):Promise<IFieldSchema> {
    // We need to handle start/due date cases like they were combined dates
    if (['startDate', 'dueDate', 'date'].includes(fieldName)) {
      fieldName = 'combinedDate';
    }

    return super.loadFieldSchema(fieldName, noWarnings);
  }

  // Ensure the given field is visible.
  // We may want to look into MutationObserver if we need this in several places.
  private waitForContainer(fieldName:string):Promise<HTMLElement> {
    return new Promise<HTMLElement>((resolve, reject) => {
      const interval = setInterval(() => {
        const container = this.findContainer(fieldName);

        if (container) {
          clearInterval(interval);
          resolve(container);
        }
      }, 100);
    });
  }

  private get rowContainer() {
    return this.table.tableAndTimelineContainer.querySelector(`.${this.classIdentifier}-table`);
  }
}
