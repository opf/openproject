//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { keyCodes } from 'core-app/modules/common/keyCodes.enum';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { ConfigurationService } from 'core-app/modules/common/config/configuration.service';
import { Injector } from '@angular/core';
import { FocusHelperService } from 'core-app/modules/common/focus/focus-helper';
import { EditFieldHandler } from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import { ClickPositionMapper } from "core-app/modules/common/set-click-position/set-click-position";
import { debugLog } from "core-app/helpers/debug_output";
import { IFieldSchema } from "core-app/modules/fields/field.base";
import { Subject } from 'rxjs';
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { EditForm } from "core-app/modules/fields/edit/edit-form/edit-form";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

export class HalResourceEditFieldHandler extends EditFieldHandler {
  // Injections
  @InjectField() FocusHelper:FocusHelperService;
  @InjectField() ConfigurationService:ConfigurationService;
  @InjectField() I18n!:I18nService;

  // Subject to fire when user demanded activation
  public $onUserActivate = new Subject<void>();

  // Current errors of the field
  public errors:string[];

  constructor(public injector:Injector,
              public form:EditForm,
              public fieldName:string,
              public schema:IFieldSchema,
              public element:HTMLElement,
              protected pathHelper:PathHelperService,
              protected withErrors?:string[]) {

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
      ClickPositionMapper.setPosition(target as HTMLInputElement, setClickOffset);
    }
  }

  public onFocusOut() {
    // In case of inline create or erroneous forms: do not save on focus loss
    // const specialField = this.resource.shouldCloseOnFocusOut(this.fieldName);
    if (this.resource.subject && this.withErrors && this.withErrors!.length === 0) {
      this.handleUserSubmit();
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
    if (this.inFlight || this.form.editMode) {
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
  public handleUserKeydown(event:JQuery.TriggeredEvent, onlyCancel = false) {
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
    this.form.change.reset(this.fieldName);
    this.deactivate(true);
  }

  /**
   * Close the field, resetting it with its display value.
   */
  public deactivate(focus = false) {
    delete this.form.activeFields[this.fieldName];
    this.onDestroy.next();
    this.onDestroy.complete();
    this.form.reset(this.fieldName, focus);
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
    } else {
      return this.I18n.t('js.inplace.errors.messages_on_field',
        { messages: this.errors.join(' ') });
    }
  }

  public previewContext(resource:HalResource) {
    return resource.previewPath();
  }
}
