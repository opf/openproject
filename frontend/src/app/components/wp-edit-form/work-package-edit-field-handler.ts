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

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageEditForm} from './work-package-edit-form';
import {WorkPackageEditContext} from './work-package-edit-context';
import {keyCodes} from 'core-app/modules/common/keyCodes.enum';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {Injector} from '@angular/core';
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';
import {EditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import {ClickPositionMapper} from "core-app/modules/common/set-click-position/set-click-position";
import {debugLog} from "core-app/helpers/debug_output";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {Subject} from 'rxjs';

export class WorkPackageEditFieldHandler extends EditFieldHandler {
  // Injections
  readonly FocusHelper:FocusHelperService = this.injector.get(FocusHelperService)
  readonly ConfigurationService = this.injector.get(ConfigurationService);
  readonly I18n:I18nService = this.injector.get(I18nService);

  // Other fields
  public editContext:WorkPackageEditContext;

  // Reference to the active component, if any
  public componentInstance:EditFieldComponent;

  // Subject to fire when user demanded activation
  public $onUserActivate = new Subject<void>();

  // Current errors of the field
  public errors:string[];

  constructor(public injector:Injector,
              public form:WorkPackageEditForm,
              public fieldName:string,
              public schema:IFieldSchema,
              public element:HTMLElement,
              protected withErrors?:string[]) {
    super();
    this.editContext = form.editContext;

    if (withErrors !== undefined) {
      this.setErrors(withErrors);
    }
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

  public get inFlight() {
    return this.form.changeset.inFlight;
  }

  public get context():WorkPackageEditContext {
    return this.form.editContext;
  }

  public get active() {
    return true;
  }

  public focus(setClickOffset?:number) {
    const target = this.element.querySelector('.wp-inline-edit--field') as HTMLElement;

    if (!target) {
      debugLog(`Tried to focus on ${this.fieldName}, but element does not (yet) exist.`);
      return;
    }

    // Focus the input
    target.focus();

    // Set selection state if input element
    if (setClickOffset && target.tagName === 'INPUT') {
      ClickPositionMapper.setPosition(target as HTMLInputElement, setClickOffset);
    }
  }

  public setErrors(newErrors:string[]) {
    this.errors = newErrors;
    this.element.classList.toggle('-error', this.isErrorenous);
  }

  /**
   * Handle a user submitting the field (e.g, ng-change)
   */
  public handleUserSubmit():Promise<any> {
    if (this.form.changeset.inFlight || this.form.editMode) {
      return Promise.resolve();
    }

    return this
      .onSubmit()
      .then(() => this.form.submit());
  }

  /**
   * Handle users pressing enter inside an edit mode.
   * Outside an edit mode, the regular save event is captured by handleUserSubmit (submit event).
   * In an edit mode, we can't derive from a submit event wheteher the user pressed enter
   * (and on what field he did that).
   */
  public handleUserKeydown(event:JQueryEventObject, onlyCancel:boolean = false) {
    // Only handle submission in edit mode
    if (this.inEditMode && !onlyCancel) {
      if (event.which === keyCodes.ENTER) {
        this.form.submit();
        return false;
      }
      return true;
    }

    // Escape editing when not in edit mode
    if (event.which === keyCodes.ESCAPE) {
      this.handleUserCancel();
      return false;
    }

    // If enter is pressed here, it will continue to handleUserSubmit()
    // due to the form submission event.
    return true;
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
    this.onDestroy.next();
    this.onDestroy.complete();
    this.editContext.reset(this.workPackage, this.fieldName, focus);
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
    return this.form.changeset.isOverridden(this.fieldName);
  }

  /**
   * Reference the form's work package
   */
  public get workPackage():WorkPackageResource {
    return this.form.workPackage;
  }

  /**
   * Reference the current set project
   */
  public get project() {
    const changeset = this.form.changeset;
    return changeset.value('project');
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
    return this.schema.name || this.fieldName;
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
