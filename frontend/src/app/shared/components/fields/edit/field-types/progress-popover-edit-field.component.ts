/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2010-2024 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import * as moment from 'moment';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject, Injector,
  OnInit,
  ViewEncapsulation,
 CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import {
  EditFieldComponent,
  OpEditingPortalChangesetToken, OpEditingPortalHandlerToken, OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';

@Component({
  templateUrl: './progress-popover-edit-field.component.html',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProgressPopoverEditFieldComponent extends EditFieldComponent implements OnInit {
  inputValue:null|string;
  turboFrameSrc:string;
  frameId:string;

  ngOnInit() {
    this.frameId = `work_package_${this.resource.id}_progress_edit_form`;
    this.turboFrameSrc = `${this.PathHelper.staticBase}/projects/${this.resource.project.id}/work_packages/${this.resource.id}/progress/edit`;
    super.ngOnInit();
  }

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    @Inject(OpEditingPortalChangesetToken) protected change:ResourceChangeset<HalResource>,
    @Inject(OpEditingPortalSchemaToken) public schema:IFieldSchema,
    @Inject(OpEditingPortalHandlerToken) readonly handler:EditFieldHandler,
    readonly cdRef:ChangeDetectorRef,
    readonly injector:Injector,
    readonly PathHelper:PathHelperService,
  ) {
    super(I18n, elementRef, change, schema, handler, cdRef, injector);
  }

  public parser(value:null|string, input:HTMLInputElement):moment.Duration {
    // Managing decimal separators in a multi-language app is a complex topic:
    // https://www.ctrl.blog/entry/html5-input-number-localization.html
    // Depending on the locale of the OS, the browser or the app itself,
    // a decimal separator could be considered valid or invalid.
    // When a decimal operator is considered invalid (e.g: 1. in Chrome with
    // 'en' locale), the input emits null as a value and its state is marked
    // not valid, but the value remains in the input. Adding a value after the
    // 'invalid' separator (e.g: 1.2) emits a valid value.
    // In order to allow both decimal separator (period and comma) in any
    // context, we check the validity of the input and, if it's not valid, we
    // default to the previous value, emulating the way the browsers work with
    // valid separators (e.g: introducing 1. would set 1 as a value).
    this.inputValue = input.value;
    if (!input.validity.valid) {
      if (value === null || input.value === '') {
        value = null;
      } else {
        value = this.value as string;
      }
    }
    return moment.duration(value, 'hours');
  }

  public formatter(value:null|string):number|null {
    if (value === null) {
      return null;
    }
    return Number(moment.duration(value).asHours().toFixed(2));
  }

  protected parseValue(val:moment.Moment | null) {
    if (val === null || this.inputValue === '') {
      return null;
    }

    let parsedValue;
    if (val.isValid()) {
      parsedValue = val.toISOString();
    } else {
      parsedValue = null;
    }

    return parsedValue;
  }
}
