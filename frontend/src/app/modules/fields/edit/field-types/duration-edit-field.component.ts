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

import { TimezoneService } from 'core-components/datetime/timezone.service';
import * as moment from 'moment';
import { Component } from "@angular/core";
import { EditFieldComponent } from "core-app/modules/fields/edit/edit-field.component";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

@Component({
  template: `
    <input type="number"
           step="0.01"
           class="inline-edit--field"
           #input
           [attr.aria-required]="required"
           [ngModel]="formatter(value)"
           (ngModelChange)="value = parser($event, input)"
           [attr.required]="required"
           (keydown)="handler.handleUserKeydown($event)"
           [disabled]="inFlight"
           [id]="handler.htmlId" />
  `
})
export class DurationEditFieldComponent extends EditFieldComponent {
  @InjectField() TimezoneService:TimezoneService;

  public parser(value:any, input:any) {
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
    if (value == null && !input.validity.valid) {
      value = this.value || 0;
    }

    return moment.duration(value, 'hours');
  }

  public formatter(value:any) {
    return Number(moment.duration(value).asHours().toFixed(2));
  }

  protected parseValue(val:moment.Moment | null) {
    if (val === null) {
      return val;
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

