//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { Injector } from '@angular/core';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { setPosition } from 'core-app/shared/helpers/set-click-position/set-click-position';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { Subject } from 'rxjs';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { EditForm } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

export class HalResourceEditFieldHandler extends EditFieldHandler {
  // Injections
  @InjectField() FocusHelper:FocusHelperService;

  @InjectField() ConfigurationService:ConfigurationService;

  @InjectField() I18n!:I18nService;

  // Subject to fire when user demanded activation
  public $onUserActivate = new Subject<void>();

  // Current errors of the field
  public errors:string[];

  constructor(
    public injector:Injector,
    public form:EditForm,
    public fieldName:string,
    public schema:IFieldSchema,
    public element:HTMLElement,
    protected pathHelper:PathHelperService,
    protected withErrors?:string[],
  ) {
    super();

    if (withErrors !== undefined) {
      this.setErrors(withErrors);
    }

    this.htmlId = `wp-${this.resource.id}-inline-edit--field-${this.fieldName}`;
    this.fieldLabel = this.schema.name || this.fieldName;
  }

  /**
   * Stop this event from propagating out of the edit field context.
   */
  public stopPropagation(evt:JQuery.TriggeredEvent) {
    evt.stopPropagation();
    return false;
  }

  public get inEditMode() {
    return this.form.editMode;
  }

  public get inFlight() {
    return this.form.change.inFlight;
  }

  public focus(setClickOffset?:number) {
    const target = this.element.querySelector('.inline-edit--field') as HTMLElement;

    if (!target) {
      debugLog(`Tried to focus on ${this.fieldName}, but element does not (yet) exist.`);
      return;
    }

    // Focus the input
    target.focus();

    // Set selection state if input element
    if (setClickOffset && target.tagName === 'INPUT') {
      setPosition(target as HTMLInputElement, setClickOffset);
    }
  }

  public async onFocusOut() {
    // In case of inline create or erroneous forms: do not save on focus loss
    // const specialField = this.resource.shouldCloseOnFocusOut(this.fieldName);
    if (this.resource.subject && this.withErrors && this.withErrors.length === 0) {
      await this.handleUserSubmit();
    }
  }

  public setErrors(newErrors:string[]) {
    this.errors = newErrors;
    this.element.classList.toggle('-error', this.isErrorenous);
  }

  /**
   * Handle a user submitting the field (e.g, ng-change)
   */
  public handleUserSubmit():Promise<unknown> {
    this.onBeforeSubmit();

    if (this.inFlight || this.form.editMode) {
      return Promise.resolve();
    }

    return this
      .onSubmit()
      .then(() => this.form.submit())
      .then(() => {
        this.blurActiveField();
      });
  }

  /**
   * Handle users pressing enter inside an edit mode.
   * Outside an edit mode, the regular save event is captured by handleUserSubmit (submit event).
   * In an edit mode, we can't derive from a submit event whether the user pressed enter
   * (and on what field he did that).
   */
  public async handleUserKeydown(event:JQuery.TriggeredEvent, onlyCancel = false) {
    // Only handle submission in edit mode
    if (this.inEditMode && !onlyCancel) {
      if (event.which === KeyCodes.ENTER) {
        await this.form.submit();
        return false;
      }
      return true;
    }

    // Escape editing when not in edit mode
    if (event.which === KeyCodes.ESCAPE) {
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
    this.form.change.reset(this.fieldName);
    if (!this.inEditMode) {
      this.deactivate(true);
    }
  }

  /**
   * Close the field, resetting it with its display value.
   */
  public deactivate(focus = false) {
    this.blurActiveField();
    delete this.form.activeFields[this.fieldName];
    this.onDestroy.next();
    this.onDestroy.complete();
    this.form.reset(this.fieldName, focus);
  }

  /**
   * Safari scrolls around like crazy if you have a focused
   * field that is about to be destroyed. So we blur it beforehand.
   * @private
   */
  public blurActiveField() {
    if (document.activeElement instanceof HTMLElement) {
      document.activeElement.blur();
    }
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
    return this.form.change.contains(this.fieldName);
  }

  /**
   * Reference the form's resource
   */
  public get resource():HalResource {
    return this.form.resource;
  }

  /**
   * Reference the current set project
   */
  public get project() {
    return this.form.change.projectedResource.project;
  }

  public errorMessageOnLabel() {
    if (!this.isErrorenous) {
      return '';
    }
    return this.I18n.t(
      'js.inplace.errors.messages_on_field',
      { messages: this.errors.join(' ') },
    );
  }

  public previewContext(resource:HalResource) {
    return resource.previewPath();
  }
}
