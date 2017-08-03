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

import {WorkPackageEditForm} from './work-package-edit-form';
import {EditField} from '../wp-edit/wp-edit-field/wp-edit-field.module';
import {WorkPackageEditContext} from './work-package-edit-context';
import {$injectFields} from '../angular/angular-injector-bridge.functions';
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../api/api-v3/hal-resources/work-package-resource.service';
import {keyCodes} from '../common/keyCodes.enum';

export class WorkPackageEditFieldHandler {
  // Injections
  public FocusHelper:any;
  public ConfigurationService:any;
  public I18n:op.I18n;

  // Scope the field has been rendered in
  public $scope:ng.IScope;

  // Other fields
  public editContext:WorkPackageEditContext;
  public fieldName:string;

  // Current errors of the field
  public errors:string[];

  constructor(public form:WorkPackageEditForm,
              public field:EditField,
              public element:JQuery,
              public withErrors:string[]) {
    $injectFields(this, 'I18n', 'ConfigurationService', 'FocusHelper');

    this.editContext = form.editContext;
    this.fieldName = field.name;

    if (withErrors !== undefined) {
      this.setErrors(withErrors);
    }



    Mousetrap(element[0]).bind('escape', () => {
      if (!this.inEditMode) {
        this.handleUserCancel();
        return false;
      }

      return true;
    });
  }

  /**
   * Stop this event from propagating out of the edit field context.
   */
  public stopPropagation(evt:JQueryEventObject) {
    evt.stopPropagation();
    return false;
  }

  public get inEditMode() {
    return this.form.editMode;
  }

  public get active() {
    return true;
  }

  public focus() {
    this.element.find('.wp-inline-edit--field').focus();
  }

  public setErrors(newErrors:string[]) {
    this.errors = newErrors;
    this.element.toggleClass('-error', this.isErrorenous);
  }

  /**
   * Handle a user submitting the field (e.g, ng-change)
   */
  public handleUserSubmit() {
    if (!this.form.editMode) {
      this.form.submit();
    }
  }

  /**
   * Handle users pressing enter inside an edit mode.
   * Outside an edit mode, the regular save event is captured by handleUserSubmit (submit event).
   * In an edit mode, we can't derive from a submit event wheteher the user pressed enter
   * (and on what field he did that).
   */
  public handleUserSubmitOnEnter(event:JQueryEventObject) {
    if (this.inEditMode && event.which === keyCodes.ENTER) {
      this.form.submit();
    }
  }

  public onlyInAccessibilityMode(callback:Function) {
    if (this.ConfigurationService.accessibilityModeEnabled()) {
      callback.apply(this);
    }
  }

  /**
   * Cancel edit
   */
  public handleUserCancel() {
    this.reset();
  }

  /**
   * Cancel any pending changes
   */
  public reset() {
    this.form.changeset.reset(this.fieldName);
    this.deactivate(true);
  }

  /**
   * Close the field, resetting it with its display value.
   */
  public deactivate(focus:boolean = false) {
    delete this.form.activeFields[this.fieldName];
    this.editContext.reset(this.workPackage, this.fieldName, focus);
    this.$scope && this.$scope.$destroy();
  }

  /**
   * Returns whether the work package is submittable.
   */
  public get isSubmittable():boolean {
    return !(this.form.editMode ||
    (this.field.required && this.field.isEmpty()) ||
    (this.isErrorenous && !this.isChanged()) ||
    this.workPackage.inFlight);
  }

  /**
   * Returns whether the field has any errors set.
   */
  public get isErrorenous():boolean {
    return this.errors.length > 0;
  }

  /**
   * Returns whether the field has been changed
   */
  public isChanged():boolean {
    return this.workPackage.$pristine[this.fieldName] !== this.workPackage[this.fieldName];
  }

  /**
   * Reference the form's work package
   */
  public get workPackage() {
    return this.form.workPackage;
  }

  /**
   * Return a unique ID for this edit field
   */
  public get htmlId() {
    return `wp-${this.workPackage.id}-inline-edit--field-${this.fieldName}`;
  }

  /**
   * Return the field label
   */
  public get fieldLabel() {
    return this.field.displayName;
  }

  public get errorMessageOnLabel() {
    if (!this.isErrorenous) {
      return '';
    }
    else {
      return this.I18n.t('js.inplace.errors.messages_on_field',
        {messages: this.errors.join(' ')});
    }
  }
}
