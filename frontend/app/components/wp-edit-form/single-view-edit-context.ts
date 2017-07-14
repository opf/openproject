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
import {$injectFields} from '../angular/angular-injector-bridge.functions';
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../api/api-v3/hal-resources/work-package-resource.service';
import {States} from '../states.service';
import {WorkPackageTableRefreshService} from '../wp-table/wp-table-refresh-request.service';
import {WorkPackageEditForm} from './work-package-edit-form';
import {EditField} from '../wp-edit/wp-edit-field/wp-edit-field.module';
import {WorkPackageEditFieldHandler} from './work-package-edit-field-handler';
import {SimpleTemplateRenderer} from '../angular/simple-template-renderer';
import {WorkPackageEditFieldController} from '../wp-edit/wp-edit-field/wp-edit-field.directive';
import {WorkPackageEditFieldGroupController} from '../wp-edit/wp-edit-field/wp-edit-field-group.directive';

export class SingleViewEditContext implements WorkPackageEditContext {

  // Injections
  public wpTableRefresh:WorkPackageTableRefreshService;
  public states:States;
  public FocusHelper:any;
  public $q:ng.IQService;
  public $timeout:ng.ITimeoutService;
  public templateRenderer:SimpleTemplateRenderer;

  constructor(public fieldGroup:WorkPackageEditFieldGroupController) {
    $injectFields(this, 'wpCacheService', 'states', 'wpTableColumns', 'wpTableRefresh',
      'FocusHelper', '$q', '$timeout', 'templateRenderer');
  }

  public async activateField(form:WorkPackageEditForm, field:EditField, errors:string[]):Promise<WorkPackageEditFieldHandler> {
    const ctrl = await this.fieldCtrl(field.name);
    const container = ctrl.editContainer;

    // Create a field handler for the newly active field
    const fieldHandler = new WorkPackageEditFieldHandler(
      form,
      field,
      container,
      errors
    );

    // Hide the display element
    ctrl.displayContainer.hide();

    // Render the edit element
    fieldHandler.$scope = this.templateRenderer.createRenderScope();
    const promise = this.templateRenderer.renderIsolated(
      // Replace the current cell
      container[0],
      fieldHandler.$scope,
      '/components/wp-edit-form/wp-edit-form.template.html',
      {
        vm: fieldHandler,
      }
    );

    return new Promise<WorkPackageEditFieldHandler>((resolve, reject) => {
      promise
        .then(() => {
          // Assure the element is visible
          this.$timeout(() => {
            ctrl.editContainer.show();
            resolve(fieldHandler);
          });
        })
        .catch(reject);
    });
  }

  public async reset(workPackage:WorkPackageResourceInterface, fieldName:string, focus:boolean = false) {
    const ctrl = await this.fieldCtrl(fieldName);
    ctrl.reset(workPackage);
    ctrl.deactivate(focus);
  }

  public requireVisible(fieldName:string):PromiseLike<undefined> {
    // All fields for the WP are already visible
    return this.$q.when();
  }

  public firstField(names:string[]) {
    return 'subject';
  }

  private async fieldCtrl(name:string):Promise<WorkPackageEditFieldController> {
    return this.fieldGroup.waitForField(name);
  }

  public onSaved(workPackage:WorkPackageResource) {
    this.wpTableRefresh.request(false, `Saved work package ${workPackage.id}`);
  }
}
