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

import {Component, ElementRef, Injector, Input, OnDestroy, OnInit} from '@angular/core';
import {StateService, Transition, TransitionService} from '@uirouter/core';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {EditableAttributeFieldComponent} from 'core-app/modules/fields/edit/field/editable-attribute-field.component';
import {input} from 'reactivestates';
import {filter, map, take} from 'rxjs/operators';
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {
  activeFieldClassName,
  activeFieldContainerClassName,
  EditForm
} from "core-app/modules/fields/edit/edit-form/edit-form";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {EditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import {EditingPortalService} from "core-app/modules/fields/edit/editing-portal/editing-portal-service";

@Component({
  selector: 'edit-form,[edit-form]',
  template: '<ng-content></ng-content>'
})
export class EditFormComponent extends EditForm<HalResource> implements OnInit, OnDestroy {
  @Input('resource') resource:HalResource;
  // ToDO
  //@Input('successState') successState?:string;
  @Input('inEditMode') initializeEditMode:boolean = false;

  public fields:{ [attribute:string]:EditableAttributeFieldComponent } = {};
  private registeredFields = input<string[]>();
  private unregisterListener:Function;

  constructor(protected readonly injector:Injector,
              protected readonly elementRef:ElementRef,
              protected readonly halEditing:HalResourceEditingService,
              protected readonly halNotification:HalResourceNotificationService,
              protected readonly $transitions:TransitionService,
              protected readonly ConfigurationService:ConfigurationService,
              protected readonly editingPortalService:EditingPortalService,
              protected readonly $state:StateService,
              protected readonly I18n:I18nService) {
    super(injector);


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
    this.destroy();
  }

  ngOnInit() {
    this.editMode = this.initializeEditMode;

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

  public async activateField(form:EditForm, schema:IFieldSchema, fieldName:string, errors:string[]):Promise<EditFieldHandler> {
    return this.waitForField(fieldName).then((ctrl) => {
      ctrl.setActive(true);
      const container = ctrl.editContainer.nativeElement;
      return this.editingPortalService.create(
          container,
          this.injector,
          form,
          schema,
          fieldName,
          errors
      );
    });
  }

  public async reset(fieldName:string, focus:boolean = false) {
    const ctrl = await this.waitForField(fieldName);
    ctrl.reset();
    ctrl.deactivate(focus);
  }

  public onSaved(isInitial:boolean, saved:HalResource) {
    this.stopEditingAndLeave(saved, isInitial);
  }

  public requireVisible(fieldName:string):Promise<void> {
    return new Promise<void>((resolve,) => {
      const interval = setInterval(() => {
        const field = this.fields[fieldName];

        if (field !== undefined) {
          clearInterval(interval);
          resolve();
        }
      }, 50);
    });
  }

  public get editing():boolean {
    return this.editMode || this.hasActiveFields();
  }

  public register(field:EditableAttributeFieldComponent) {
    this.fields[field.fieldName] = field;
    this.registeredFields.putValue(_.keys(this.fields));

    const shouldActivate =
        (this.editMode && !this.skipField(field) || this.activeFields[field.fieldName]);

    if (shouldActivate) {
      field.activateOnForm(true);
    }
  }

  public waitForField(name:string):Promise<EditableAttributeFieldComponent> {
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
    _.each(this.fields, ctrl => this.activate(ctrl.fieldName));
  }

  public stop() {
    this.editMode = false;
    this.halEditing.stopEditing(this.resource.id!);
    this.destroy();

    if (this.resource.isNew) {
      // ToDo
      // this.wpCreate.cancelCreation();
    }
  }

  public save() {
    const isInitial = this.resource.isNew;
    return this
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

  protected focusOnFirstError():void {
    // Focus the first field that is erroneous
    jQuery(this.elementRef.nativeElement)
        .find(`.${activeFieldContainerClassName}.-error .${activeFieldClassName}`)
        .first()
        .trigger('focus');
  }

  private skipField(field:EditableAttributeFieldComponent) {
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
    const changed = this.change.changes[fieldName];

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
