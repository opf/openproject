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
import {injectorBridge} from '../angular/angular-injector-bridge.functions';

export class WorkPackageEditFieldHandler {
  // Injections
  public FocusHelper:any;
  public I18n:op.I18n;

  // Other fields
  public editContext:WorkPackageEditContext;
  public fieldName:string;

  // Current errors of the field
  public errors:string[];

  constructor(public form:WorkPackageEditForm,
              public field:EditField,
              public element:JQuery,
              public withErrors: string[]) {
    injectorBridge(this);

    this.editContext = form.editContext;
    this.fieldName = field.name;

    if (withErrors !== undefined) {
      this.setErrors(withErrors);
    }

    Mousetrap(element[0]).bind('escape', () => {
      this.reset();
      return false;
    });
  }

  /**
   * Stop this event from propagating out of the edit field context.
   */
  public stopPropagation(evt) {
    evt.stopPropagation();
    return false;
  }

  // Can we remove this?
  public shouldFocus() {
    return true;
  }

  public focus() {
    this.FocusHelper.focusElement(this.element.find('.wp-inline-edit--field '), true);
  }

  public setErrors(newErrors:string[]) {
    this.errors = newErrors;
    this.element.toggleClass('-error', this.isErrorenous);
  }

  /**
   * Handle a user submitting the field (e.g, ng-change)
   */
  public handleUserSubmit() {
    this.form.submit();
  }

  // TODO remove
  public handleUserSubmitOnEnter() {
  }

  /**
   * Cancel any pending changes
   */
  public reset() {
    this.workPackage.restoreFromPristine(this.fieldName);
    delete this.workPackage.$pristine[this.fieldName];
    this.deactivate();
  }

  /**
   * Close the field, resetting it with its display value.
   */
  public deactivate() {
    delete this.form.activeFields[this.fieldName];
    this.editContext.reset(this.workPackage, this.fieldName);
  }

  /**
   * Returns whether the work package is submittable.
   */
  public get isSubmittable(): boolean {
    return !(this.form.editMode ||
    (this.field.required && this.field.isEmpty()) ||
    (this.isErrorenous && !this.isChanged()) ||
    this.workPackage.inFlight);
  }

  /**
   * Returns whether the field has any errors set.
   */
  public get isErrorenous(): boolean {
    return this.errors.length > 0;
  }

  /**
   * Returns whether the field has been changed
   */
  public isChanged(): boolean {
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
    return this.fieldName; // TOOD overridden fields labels?
  }

  public get errorMessageOnLabel() {
    if (!this.isErrorenous) {
      return '';
    }
    else {
      return this.I18n.t('js.inplace.errors.messages_on_field',
        { messages: this.errors.join(' ') });
    }
  }
}

WorkPackageEditFieldHandler.$inject = ['I18n', 'FocusHelper'];
