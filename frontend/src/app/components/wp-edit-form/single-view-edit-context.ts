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

import {StateService} from '@uirouter/core';
import {WorkPackageEditFieldGroupComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field-group.directive';
import {WorkPackageEditFieldComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field.component';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {States} from '../states.service';
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';
import {WorkPackageTableSelection} from '../wp-fast-table/state/wp-table-selection.service';
import {Injector} from '@angular/core';
import {WorkPackageEditContext} from 'core-components/wp-edit-form/work-package-edit-context';
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';
import {WorkPackageEditForm} from 'core-components/wp-edit-form/work-package-edit-form';
import {WorkPackageEditFieldHandler} from 'core-components/wp-edit-form/work-package-edit-field-handler';
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';
import {WorkPackageEditingPortalService} from "core-app/modules/fields/edit/editing-portal/wp-editing-portal-service";
import {IFieldSchema} from "core-app/modules/fields/field.base";

export class SingleViewEditContext implements WorkPackageEditContext {

  // Injections
  public wpTableRefresh:WorkPackageTableRefreshService = this.injector.get(WorkPackageTableRefreshService);
  public states:States = this.injector.get(States);
  public FocusHelper:FocusHelperService = this.injector.get(FocusHelperService);
  public $state:StateService = this.injector.get(StateService);
  public wpNotificationsService:WorkPackageNotificationService = this.injector.get(WorkPackageNotificationService);
  public wpEditingPortalService:WorkPackageEditingPortalService = this.injector.get(WorkPackageEditingPortalService);
  protected wpTableSelection:WorkPackageTableSelection = this.injector.get(WorkPackageTableSelection);

  // other fields
  public successState:string;

  constructor(readonly injector:Injector,
              readonly fieldGroup:WorkPackageEditFieldGroupComponent) {
  }

  public async activateField(form:WorkPackageEditForm, schema:IFieldSchema, fieldName:string, errors:string[]):Promise<WorkPackageEditFieldHandler> {
    return this.fieldCtrl(fieldName).then((ctrl) => {
      ctrl.active = true;
      const container = ctrl.editContainer.nativeElement;
      return this.wpEditingPortalService.create(
        container,
        form,
        schema,
        fieldName,
        errors
      );
    });
  }

  public async reset(workPackage:WorkPackageResource, fieldName:string, focus:boolean = false) {
    const ctrl = await this.fieldCtrl(fieldName);
    ctrl.reset(workPackage);
    ctrl.deactivate(focus);
  }

  public onSaved(isInitial:boolean, savedWorkPackage:WorkPackageResource) {
    this.fieldGroup.stopEditingAndLeave(savedWorkPackage, isInitial);
  }

  public requireVisible(fieldName:string):Promise<void> {
    return new Promise<void>((resolve,) => {
      const interval = setInterval(() => {
        const field = this.fieldGroup.fields[fieldName];

        if (field !== undefined) {
          clearInterval(interval);
          resolve();
        }
      }, 50);
    });
  }

  public firstField(names:string[]) {
    return 'subject';
  }

  private fieldCtrl(name:string):Promise<WorkPackageEditFieldComponent> {
    return this.fieldGroup.waitForField(name);
  }
}
