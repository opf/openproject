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

import {Component, Inject, Injector, Input, OnDestroy, OnInit} from '@angular/core';
import {StateService, Transition, TransitionService} from '@uirouter/core';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {WorkPackageEditFieldComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field.component';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {input} from 'reactivestates';
import {filter, map, take, takeUntil} from 'rxjs/operators';
import {States} from '../../states.service';
import {SingleViewEditContext} from '../../wp-edit-form/single-view-edit-context';
import {WorkPackageEditForm} from '../../wp-edit-form/work-package-edit-form';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageTableSelection} from '../../wp-fast-table/state/wp-table-selection.service';
import {WorkPackageNotificationService} from '../wp-notification.service';
import {WorkPackageCreateService} from './../../wp-new/wp-create.service';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {IWorkPackageEditingServiceToken} from "../../wp-edit-form/work-package-editing.service.interface";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";

@Component({
  selector: 'wp-edit-field-group,[wp-edit-field-group]',
  template: '<ng-content></ng-content>'
})
export class WorkPackageEditFieldGroupComponent implements OnInit, OnDestroy {
  @Input('workPackage') workPackage:WorkPackageResource;
  @Input('successState') successState?:string;
  @Input('inEditMode') initializeEditMode:boolean = false;

  public form:WorkPackageEditForm;
  public fields:{ [attribute:string]:WorkPackageEditFieldComponent } = {};
  private registeredFields = input<string[]>();
  private unregisterListener:Function;

  constructor(protected states:States,
              protected injector:Injector,
              @Inject(IWorkPackageCreateServiceToken) protected wpCreate:WorkPackageCreateService,
              @Inject(IWorkPackageEditingServiceToken) protected wpEditing:WorkPackageEditingService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected wpTableSelection:WorkPackageTableSelection,
              protected wpTableFocus:WorkPackageTableFocusService,
              protected $transitions:TransitionService,
              protected ConfigurationService:ConfigurationService,
              readonly $state:StateService,
              readonly I18n:I18nService) {

    const confirmText = I18n.t('js.work_packages.confirm_edit_cancel');
    const requiresConfirmation = ConfigurationService.warnOnLeavingUnsaved();

    this.unregisterListener = $transitions.onStart({}, (transition:Transition) => {
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
    this.form = WorkPackageEditForm.createInContext(this.injector, context, this.workPackage, this.initializeEditMode);
    this.states.workPackages.get(this.workPackage.id)
      .values$()
      .pipe(
        takeUntil(componentDestroyed(this)),
      )
      .subscribe((wp) => {
        _.each(this.fields, (ctrl) => this.updateDisplayField(ctrl, wp));
      });

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
      (this.editMode && !this.skipField(field) || this.form.activeFields[field.fieldName])

    if (shouldActivate) {
      field.activateOnForm(true);
    } else {
      this.states.workPackages
        .get(this.workPackage.id)
        .valuesPromise()
        .then(wp => this.updateDisplayField(field, wp!));
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
    this.wpEditing.stopEditing(this.workPackage.id);
    this.form.destroy();
  }

  public saveWorkPackage() {
    const isInitial = this.workPackage.isNew;
    return this.form
      .submit()
      .then((savedWorkPackage) => {
        this.stopEditingAndLeave(savedWorkPackage, isInitial);
      });
  }

  public stopEditingAndLeave(savedWorkPackage:WorkPackageResource, isInitial:boolean) {
    this.stop();

    if (this.successState) {
      this.$state.go(this.successState, {workPackageId: savedWorkPackage.id})
        .then(() => {
          this.wpTableFocus.updateFocus(savedWorkPackage.id);
          this.wpNotificationsService.showSave(savedWorkPackage, isInitial);
        });
    }
  }

  private updateDisplayField(field:WorkPackageEditFieldComponent, wp:WorkPackageResource) {
    field.workPackage = wp;
    field.render();
  }

  private skipField(field:WorkPackageEditFieldComponent) {
    const fieldName = field.fieldName;

    const isSkipField = fieldName === 'status' || fieldName === 'type';
    return (isSkipField && this.workPackage[fieldName]);
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
