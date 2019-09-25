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
import {WorkPackageViewFocusService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {input} from 'reactivestates';
import {filter, map, take, takeUntil} from 'rxjs/operators';
import {States} from '../../states.service';
import {SingleViewEditContext} from '../../wp-edit-form/single-view-edit-context';

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageCreateService} from './../../wp-new/wp-create.service';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageViewSelectionService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import {EditForm} from "core-app/modules/fields/edit/edit-form/edit-form";
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";

@Component({
  selector: 'wp-edit-field-group,[wp-edit-field-group]',
  template: '<ng-content></ng-content>'
})
export class WorkPackageEditFieldGroupComponent implements OnInit, OnDestroy {
  @Input('workPackage') workPackage:WorkPackageResource;
  @Input('successState') successState?:string;
  @Input('inEditMode') initializeEditMode:boolean = false;

  public form:EditForm;
  public fields:{ [attribute:string]:WorkPackageEditFieldComponent } = {};
  private registeredFields = input<string[]>();
  private unregisterListener:Function;

  constructor(protected states:States,
              protected injector:Injector,
              protected wpCreate:WorkPackageCreateService,
              protected halEditing:HalResourceEditingService,
              protected halNotification:HalResourceNotificationService,
              protected wpTableSelection:WorkPackageViewSelectionService,
              protected wpTableFocus:WorkPackageViewFocusService,
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
    this.form = EditForm.createInContext(this.injector, context, this.workPackage, this.initializeEditMode);

    if (this.initializeEditMode) {
      this.start();
    }

    // Stop editing whenever a work package was saved
    if (this.initializeEditMode && this.workPackage.isNew) {
      this.wpCreate.onNewWorkPackage()
        .pipe(
          takeUntil(componentDestroyed(this))
        )
        .subscribe((wp:WorkPackageResource) => {
          this.form.editMode = false;
          this.stopEditingAndLeave(wp, true);
        });
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
    this.halEditing.stopEditing(this.workPackage.id!);
    this.form.destroy();

    if (this.workPackage.isNew) {
      this.wpCreate.cancelCreation();
    }
  }

  public saveWorkPackage() {
    const isInitial = this.workPackage.isNew;
    return this.form
      .submit()
      .then((savedWorkPackage:WorkPackageResource) => {
        this.stopEditingAndLeave(savedWorkPackage, isInitial);
      });
  }

  public stopEditingAndLeave(savedWorkPackage:WorkPackageResource, isInitial:boolean) {
    this.stop();

    if (this.successState) {
      this.$state.go(this.successState, {workPackageId: savedWorkPackage.id})
        .then(() => {
          this.wpTableFocus.updateFocus(savedWorkPackage.id!);
          this.halNotification.showSave(savedWorkPackage, isInitial);
        });
    }
  }

  private skipField(field:WorkPackageEditFieldComponent) {
    const fieldName = field.fieldName;

    const isSkipField = fieldName === 'status' || fieldName === 'type';

    // Only skip status or type
    if (!isSkipField) {
      return false;
    }

    // Only skip if value present and not changed in changeset
    const hasDefault = this.workPackage[fieldName];
    const changed = this.form.change.changes[fieldName];

    return hasDefault && !changed;
  }

  private allowedStateChange(toState:any, toParams:any, fromState:any, fromParams:any) {

    // In new/copy mode, transitions to the same controller are allowed
    if (fromState.name.match(/\.(new|copy)$/)) {
      return toState.data && toState.data.allowMovingInEditMode;
    }

    // When editing an existing WP, transitions on the same WP id are allowed
    return toParams.workPackageId !== undefined && toParams.workPackageId === fromParams.workPackageId;
  }
}
