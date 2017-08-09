// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {WorkPackageEditContext} from './work-package-edit-context';
import {CellBuilder, editCellContainer, tdClassName} from '../wp-fast-table/builders/cell-builder';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {States} from '../states.service';
import {WorkPackageTableRefreshService} from '../wp-table/wp-table-refresh-request.service';
import {WorkPackageEditForm} from './work-package-edit-form';
import {EditField} from '../wp-edit/wp-edit-field/wp-edit-field.module';
import {WorkPackageEditFieldHandler} from './work-package-edit-field-handler';
import {SimpleTemplateRenderer} from '../angular/simple-template-renderer';

export class TableRowEditContext implements WorkPackageEditContext {

  // Injections
  public templateRenderer:SimpleTemplateRenderer;
  public wpTableRefresh:WorkPackageTableRefreshService;
  public wpTableColumns:WorkPackageTableColumnsService;
  public states:States;
  public FocusHelper:any;
  public $q:ng.IQService;
  public $timeout:ng.ITimeoutService;

  // other fields
  public successState:string;

  // Use cell builder to reset edit fields
  private cellBuilder = new CellBuilder();

  constructor(public workPackageId:string, public classIdentifier:string) {
    injectorBridge(this);
  }

  public findContainer(fieldName:string):JQuery {
    return this.rowContainer.find(`.${tdClassName}.${fieldName} .${editCellContainer}`).first();
  }

  public activateField(form:WorkPackageEditForm, field:EditField, fieldName:string, errors:string[]):ng.IPromise<WorkPackageEditFieldHandler> {
    const cell = this.findContainer(fieldName);

    // Create a field handler for the newly active field
    const fieldHandler = new WorkPackageEditFieldHandler(
      form,
      fieldName,
      field,
      cell,
      errors
    );

    fieldHandler.$scope = this.templateRenderer.createRenderScope();
    const promise = this.templateRenderer.renderIsolated(
      // Replace the current cell
      cell,
      fieldHandler.$scope,
      '/components/wp-edit-form/wp-edit-form.template.html',
      {
        vm: fieldHandler,
      }
    );

    return promise.then(() => {
      // Assure the element is visible
      return this.$timeout(() => {
        fieldHandler.focus();
        return fieldHandler;
      });
    });
  }

  public refreshField(field:EditField, handler:WorkPackageEditFieldHandler) {
    handler.$scope.$evalAsync(() => handler.field = field);
  }

  public reset(workPackage:WorkPackageResourceInterface, fieldName:string, focus?:boolean) {
    const cell = this.findContainer(fieldName);

    if (cell.length) {
      this.cellBuilder.refresh(cell[0], workPackage, fieldName);

      if (focus) {
        this.FocusHelper.focusElement(cell);
      }
    }
  }

  public requireVisible(fieldName:string):Promise<undefined> {
    this.wpTableColumns.addColumn(fieldName);
    return this.waitForContainer(fieldName);
  }

  public firstField(names:string[]) {
    return 'subject';
  }

  // Ensure the given field is visible.
  // We may want to look into MutationObserver if we need this in several places.
  private waitForContainer(fieldName:string):Promise<undefined> {
    const deferred = this.$q.defer<undefined>();

    const interval = setInterval(() => {
      const container = this.findContainer(fieldName);

      if (container.length > 0) {
        clearInterval(interval);
        deferred.resolve();
      }
    }, 100);

    return deferred.promise;
  }

  private get rowContainer() {
    return jQuery(`.${this.classIdentifier}-table`);
  }
}

TableRowEditContext.$inject = [
  'wpCacheService', 'states', 'wpTableColumns', 'wpTableRefresh',
  'FocusHelper', '$q', '$timeout', 'templateRenderer'
];
