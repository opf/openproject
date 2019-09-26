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

import {Component, Injector, Input, OnDestroy, OnInit} from '@angular/core';
import {StateService, Transition, TransitionService} from '@uirouter/core';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {WorkPackageEditFieldComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field.component';
import {input} from 'reactivestates';
import {filter, map, take} from 'rxjs/operators';

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {EditForm} from "core-app/modules/fields/edit/edit-form/edit-form";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {States} from "core-components/states.service";
import {SingleViewEditContext} from "core-components/wp-edit-form/single-view-edit-context";

@Component({
  selector: 'edit-field-group,[edit-field-group]',
  template: '<ng-content></ng-content>'
})
export class EditFieldGroupComponent implements OnInit, OnDestroy {
  @Input('resource') resource:HalResource;
  //@Input('successState') successState?:string;
  @Input('inEditMode') initializeEditMode:boolean = false;

  public form:EditForm;
  public fields:{ [attribute:string]:WorkPackageEditFieldComponent } = {};
  private registeredFields = input<string[]>();
  private unregisterListener:Function;

  constructor(protected states:States,
              protected injector:Injector,
              protected halEditing:HalResourceEditingService,
              protected halNotification:HalResourceNotificationService,
              protected $transitions:TransitionService,
              protected ConfigurationService:ConfigurationService,
              readonly $state:StateService,
              readonly I18n:I18nService) {

    const confirmText = I18n.t('js.work_packages.confirm_edit_cancel');
    const requiresConfirmation = ConfigurationService.warnOnLeavingUnsaved();

    this.unregisterListener = $transitions.onBefore({}, (transition:Transition) => {
      if (!this.editing) {
        return undefined;
      }

      // Show confirmation message when transitioning to a new state
      // that's not withing the edit mode.
      const toState = transition.to();
      const fromState = transition.from();
      const fromParams = transition.params('from');
      const toParams = transition.params('to');
      if (!this.allowedStateChange(toState, toParams, fromState, fromParams)) {
        if (requiresConfirmation && !window.confirm(confirmText)) {
          return false;
        }

        this.stop();
      }

      return true;
    });
  }

  ngOnDestroy() {
    this.unregisterListener();
    this.form.destroy();
  }

  ngOnInit() {
    const context = new SingleViewEditContext(this.injector, this);
    this.form = EditForm.createInContext(this.injector, context, this.resource, this.initializeEditMode);

    if (this.initializeEditMode) {
      this.start();
    }

    // Stop editing whenever a work package was saved
    if (this.initializeEditMode && this.resource.isNew) {
      // ToDO: Move to generic service
      /*
      this.wpCreate.onNewWorkPackage()
          .pipe(
              takeUntil(componentDestroyed(this))
          )
          .subscribe((wp:WorkPackageResource) => {
            this.form.editMode = false;
            this.stopEditingAndLeave(wp, true);
          });

       */
    }
  }

  public get editing():boolean {
    return this.editMode || this.form.hasActiveFields();
  }

  public get editMode() {
    return this.form.editMode;
  }

  public register(field:WorkPackageEditFieldComponent) {
    this.fields[field.fieldName] = field;
    this.registeredFields.putValue(_.keys(this.fields));

    const shouldActivate =
        (this.editMode && !this.skipField(field) || this.form.activeFields[field.fieldName]);

    if (shouldActivate) {
      field.activateOnForm(true);
    }
  }

  public waitForField(name:string):Promise<WorkPackageEditFieldComponent> {
    return this.registeredFields
        .values$()
        .pipe(
            filter(keys => keys.indexOf(name) >= 0),
            take(1),
            map(() => this.fields[name])
        )
        .toPromise();
  }

  public start() {
    _.each(this.fields, ctrl => this.form.activate(ctrl.fieldName));
  }

  public stop() {
    this.form.editMode = false;
    this.halEditing.stopEditing(this.resource.id!);
    this.form.destroy();

    if (this.resource.isNew) {
      // ToDo
      // this.wpCreate.cancelCreation();
    }
  }

  public save() {
    const isInitial = this.resource.isNew;
    return this.form
        .submit()
        .then((savedResource:HalResource) => {
          this.stopEditingAndLeave(savedResource, isInitial);
        });
  }

  public stopEditingAndLeave(savedResource:HalResource, isInitial:boolean) {
    this.stop();

    // TodO: Move to generic service
    /*
    if (this.successState) {
      this.$state.go(this.successState, {workPackageId: savedResource.id})
          .then(() => {
            this.wpTableFocus.updateFocus(savedResource.id!);
            this.halNotification.showSave(savedResource, isInitial);
          });
    }

     */
  }

  private skipField(field:WorkPackageEditFieldComponent) {
    const fieldName = field.fieldName;

    // ToDO: Move to generic service
    /*
    const isSkipField = fieldName === 'status' || fieldName === 'type';

    // Only skip status or type
    if (!isSkipField) {
      return false;
    }

     */

    // Only skip if value present and not changed in changeset
    const hasDefault = this.resource[fieldName];
    const changed = this.form.change.changes[fieldName];

    return hasDefault && !changed;
  }

  private allowedStateChange(toState:any, toParams:any, fromState:any, fromParams:any) {
    // ToDo Move to its own service
    return true;

    /*
    // In new/copy mode, transitions to the same controller are allowed
    if (fromState.name.match(/\.(new|copy)$/)) {
      return toState.data && toState.data.allowMovingInEditMode;
    }

    // When editing an existing WP, transitions on the same WP id are allowed
    return toParams.workPackageId !== undefined && toParams.workPackageId === fromParams.workPackageId;

     */
  }
}
