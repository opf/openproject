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

import {Component} from "@angular/core";
import * as moment from "moment";
import {TimezoneService} from "core-components/datetime/timezone.service";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import {EditField} from "core-app/modules/fields/edit/edit.field.module";

@Component({
  template: `
    <op-date-picker
      tabindex="-1"
      (onChange)="onValueSelected($event)"
      [initialDate]="field.defaultDate">

      <input [ngModel]="formatter(field.value)"
             (ngModelChange)="field.value = parser($event);"
             type="text"
             class="wp-inline-edit--field"
             (keydown)="handler.handleUserKeydown($event)"
             [attr.required]="field.required"
             [disabled]="field.inFlight"
             [attr.placeholder]="field.placeholder"
             [id]="handler.htmlId" />

    </op-date-picker>

  `
})
export class DateEditFieldComponent extends EditFieldComponent {
  public field:DateEditField;
  readonly timezoneService = this.injector.get(TimezoneService);

  public onValueSelected(data:string) {
    this.field.value = this.parser(data);
    this.handler.handleUserSubmit();
  }

  public parser(data:any) {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      return data;
    } else {
      return null;
    }
  }

  public formatter(data:any) {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      var d = this.timezoneService.parseDate(data);
      return this.timezoneService.formattedISODate(d);
    } else {
      return null;
    }
  }
}

export class DateEditField extends EditField {
  public component = DateEditFieldComponent;

  /**
   * Return the default date for the datepicker instance.
   * If this field is the finish date, we select the start date + 1 as the default.
   */
  public get defaultDate():String {
    const isDueDate = this.name === 'dueDate';

    if (isDueDate) {
      return this.resource.startDate;
    }

    return '';
  }
}
