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
import {DatePickerModal} from "core-components/datepicker/datepicker.modal";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {take} from "rxjs/operators";

@Component({
  template: `

    <input [ngModel]="formatter(value)"
           (ngModelChange)="value = parser($event);"
           type="text"
           class="inline-edit--field"
           (keydown)="handler.handleUserKeydown($event)"
           [attr.required]="required"
           [disabled]="inFlight"
           [attr.placeholder]="placeholder"
           [id]="handler.htmlId"/>


  `
})
export class DateEditFieldComponent extends EditFieldComponent implements OnInit {
  @InjectField() readonly timezoneService:TimezoneService;
  @InjectField() opModalService:OpModalService;

  ngOnInit() {
    super.ngOnInit();
    this.showDatePickerModal();
  }

  public onValueSelected(data:string) {
    this.value = this.parser(data);
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

  private showDatePickerModal():void {
    const modal = this
      .opModalService
      .show(DatePickerModal, this.injector, { changeset: this.change });

    setTimeout(() => {
      const modalElement = jQuery(modal.elementRef.nativeElement).find('.datepicker-modal');
      const field = jQuery(this.elementRef.nativeElement);
      modal.reposition(modalElement, field);
    });

    modal
      .closingEvent
      .pipe(take(1))
      .subscribe(() => {
        this.handler.handleUserSubmit();
      });
  }
}
