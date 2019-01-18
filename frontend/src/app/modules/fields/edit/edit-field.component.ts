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

import {
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  InjectionToken,
  Injector,
  OnDestroy,
  OnInit
} from "@angular/core";
import {EditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {IWorkPackageEditingServiceToken} from "core-components/wp-edit-form/work-package-editing.service.interface";
import {WorkPackageEditingService} from "core-components/wp-edit-form/work-package-editing-service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {Field, IFieldSchema} from "core-app/modules/fields/field.base";
import {WorkPackageChangeset} from "core-components/wp-edit-form/work-package-changeset";

export const OpEditingPortalSchemaToken = new InjectionToken('wp-editing-portal--schema');
export const OpEditingPortalHandlerToken = new InjectionToken('wp-editing-portal--handler');
export const OpEditingPortalChangesetToken = new InjectionToken('wp-editing-portal--changeset');

export const overflowingContainerSelector = '.__overflowing_element_container';
export const overflowingContainerAttribute = 'overflowingIdentifier';

@Component({
  template: ''
})
export class EditFieldComponent extends Field implements OnInit, OnDestroy {

  /** Self reference */
  public self = this;

  /** JQuery accessor to element ref */
  protected $element:JQuery<HTMLElement>;

  constructor(readonly I18n:I18nService,
              readonly elementRef:ElementRef,
              @Inject(IWorkPackageEditingServiceToken) protected wpEditing:WorkPackageEditingService,
              @Inject(OpEditingPortalChangesetToken) protected changeset:WorkPackageChangeset,
              @Inject(OpEditingPortalSchemaToken) public schema:IFieldSchema,
              @Inject(OpEditingPortalHandlerToken) readonly handler:EditFieldHandler,
              readonly cdRef:ChangeDetectorRef,
              readonly injector:Injector) {
    super();
    this.initialize();

    this.wpEditing.state(this.changeset.workPackage.id)
      .values$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe((changeset) => {

        if (!this.changeset.empty && this.changeset.form) {
          const fieldSchema = changeset.form!.schema[this.name];

          if (!fieldSchema) {
            return handler.deactivate(false);
          }

          this.changeset = changeset;
          this.schema = fieldSchema;
          this.initialize();
          this.cdRef.markForCheck();
        }
      });
  }

  ngOnInit():void {
    this.$element = jQuery(this.elementRef.nativeElement);
  }

  ngOnDestroy() {
    // Nothing to do
  }

  public get overflowingSelector() {
    if (this.$element) {
      return this.$element
        .closest(overflowingContainerSelector)
        .data(overflowingContainerAttribute);
    } else {
      return null;
    }
  }

  public get inFlight() {
    return this.handler.inFlight;
  }

  public get value() {
    return this.changeset.value(this.name);
  }

  public get name() {
    // Get the mapped schema name, as this is not always the attribute
    // e.g., startDate in table for milestone => date attribute
    return this.changeset.getSchemaName(this.handler.fieldName);
  }

  public set value(value:any) {
    this.changeset.setValue(this.name, this.parseValue(value));
  }

  public get placeholder() {
    if (this.name === 'subject') {
      return this.I18n.t('js.placeholders.subject');
    }

    return '';
  }

  public get resource() {
    return this.changeset.workPackage;
  }

  public get groupName() {
    return this.changeset.form!.schema[this.name].attributeGroup;
  }

  /**
   * Initialize the field after constructor was called.
   */
  protected initialize() {
  }

  /**
   * Parse the value from the model for setting
   */
  protected parseValue(val:any) {
    return val;
  }
}
