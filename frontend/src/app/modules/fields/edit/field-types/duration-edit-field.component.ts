// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {TimezoneService} from 'core-components/datetime/timezone.service';
import * as moment from 'moment';
import {Component} from "@angular/core";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

@Component({
  template: `
    <input type="number"
           step="0.01"
           class="inline-edit--field"
           [attr.aria-required]="required"
           [ngModel]="formatter(value)"
           (ngModelChange)="value = parser($event)"
           [attr.required]="required"
           (keydown)="handler.handleUserKeydown($event)"
           [disabled]="inFlight"
           [id]="handler.htmlId" />
  `
})
export class DurationEditFieldComponent extends EditFieldComponent {
  @InjectField() TimezoneService:TimezoneService;

  public parser(value:any) {
    if (!isNaN(value)) {
      let floatValue = parseFloat(value);
      return moment.duration(floatValue, 'hours');
    }

    return value;
  }

  public formatter(value:any) {
    return Number(moment.duration(value).asHours().toFixed(2));
  }

  protected parseValue(val:moment.Moment | null) {
    if (val === null) {
      return val
    }

    let parsedValue;
    if (val.isValid()) {
      parsedValue = val.toISOString();
    } else {
      parsedValue = this.resource[this.name];
    }

    return parsedValue;
  }
}

