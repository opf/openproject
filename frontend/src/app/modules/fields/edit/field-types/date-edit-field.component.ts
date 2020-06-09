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

import {Component, OnInit} from "@angular/core";
import * as moment from "moment";
import {TimezoneService} from "core-components/datetime/timezone.service";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {OpModalService} from "core-components/op-modals/op-modal.service";

@Component({
  template: `
    <op-date-picker
        tabindex="-1"
        (onChange)="onValueSelected($event)"
        (onCancel)="onCancel()"
        [initialDate]="formatter(value)"
        [required]="required"
        [disabled]="inFlight"
        [id]="handler.htmlId"
        classes="inline-edit--field">
    </op-date-picker>
  `
})
export class DateEditFieldComponent extends EditFieldComponent implements OnInit {
  @InjectField() readonly timezoneService:TimezoneService;
  @InjectField() opModalService:OpModalService;

  ngOnInit() {
    super.ngOnInit();
  }

  public onValueSelected(data:string) {
    this.value = this.parser(data);
    this.handler.handleUserSubmit();
  }

  public onCancel() {
    this.handler.handleUserCancel();
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
