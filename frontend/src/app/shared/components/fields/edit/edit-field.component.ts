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

import {
  ChangeDetectorRef,
  Directive,
  ElementRef,
  Inject,
  InjectionToken,
  Injector,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Field, IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export const OpEditingPortalSchemaToken = new InjectionToken('editing-portal--schema');
export const OpEditingPortalHandlerToken = new InjectionToken('editing-portal--handler');
export const OpEditingPortalChangesetToken = new InjectionToken('editing-portal--changeset');

export const overflowingContainerSelector = '.__overflowing_element_container';
export const overflowingContainerAttribute = 'overflowingIdentifier';

export const editModeClassName = '-editing';

@Directive()
export abstract class EditFieldComponent extends Field implements OnInit, OnDestroy {
  /** Self reference */
  public self = this;

  /** JQuery accessor to element ref */
  protected $element:JQuery;

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    @Inject(OpEditingPortalChangesetToken) protected change:ResourceChangeset<HalResource>,
    @Inject(OpEditingPortalSchemaToken) public schema:IFieldSchema,
    @Inject(OpEditingPortalHandlerToken) readonly handler:EditFieldHandler,
    readonly cdRef:ChangeDetectorRef,
    readonly injector:Injector,
  ) {
    super();

    this.updateFromChangeset(change);
  }

  ngOnInit():void {
    this.$element = jQuery(this.elementRef.nativeElement as HTMLElement);
    this.initialize();

    if (this.change.state) {
      this.change.state
        .values$()
        .pipe(
          this.untilDestroyed(),
        )
        .subscribe((change) => {
          const fieldSchema = change.schema.ofProperty(this.name);

          if (!fieldSchema) {
            return this.handler.deactivate(false);
          }

          this.updateFromChangeset(change);
          this.initialize();
          this.cdRef.markForCheck();
        });
    }
  }

  public get overflowingSelector() {
    if (this.$element) {
      return this.$element
        .closest(overflowingContainerSelector)
        .data(overflowingContainerAttribute);
    }
    return null;
  }

  public get inFlight() {
    return this.handler.inFlight;
  }

  public get value() {
    return this.resource[this.name];
  }

  public set value(value:any) {
    this.resource[this.name] = this.parseValue(value);
  }

  public get placeholder() {
    if (this.name === 'subject') {
      return this.I18n.t('js.placeholders.subject');
    }

    return '';
  }

  /**
   * Initialize the field after constructor was called.
   */
  protected initialize() {
  }

  /**
   * Update resource and properties from changeset
   */
  private updateFromChangeset(change:ResourceChangeset) {
    this.change = change;
    this.resource = this.change.projectedResource;
    this.schema = this.change.schema.ofProperty(this.handler.fieldName) || this.schema;

    // Get the mapped schema name, as this is not always the attribute
    // e.g., startDate in table for milestone => date attribute
    this.name = this.change.schema.mappedName(this.handler.fieldName);
  }

  /**
   * Parse the value from the model for setting
   */
  protected parseValue(val:any) {
    return val;
  }
}
