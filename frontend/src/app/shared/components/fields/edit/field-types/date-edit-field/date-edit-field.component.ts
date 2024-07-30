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

import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import * as moment from 'moment';
import { EditFieldComponent } from 'core-app/shared/components/fields/edit/edit-field.component';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

@Component({
  template: `
    <op-basic-single-date-picker
      [(ngModel)]="value"
      (keydown.escape)="onCancel()"
      (keydown.enter)="handler.handleUserSubmit()"
      (picked)="handler.handleUserSubmit()"
      class="inline-edit--field"
      [id]="handler.htmlId"
      [required]="required"
      [disabled]="inFlight"
      [opAutofocus]="autofocus"
    ></op-basic-single-date-picker>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DateEditFieldComponent extends EditFieldComponent implements OnInit {
  @InjectField() readonly timezoneService:TimezoneService;

  autofocus = false;

  ngOnInit():void {
    super.ngOnInit();
    // Open the datepicker when the field is not part of an editing form.
    this.autofocus = !this.handler.inEditMode;
  }

  public get value():string {
    return this.formatter(this.resource[this.name]) || '';
  }

  public set value(value:string) {
    this.resource[this.name] = this.parseValue(value);
  }

  public parseValue(data:string) {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      return data;
    }
    return null;
  }

  public onCancel():void {
    this.handler.handleUserCancel();
    this.onModalClosed();
  }

  public formatter(data:string):string|null {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      const d = this.timezoneService.parseDate(data);
      return this.timezoneService.formattedISODate(d);
    }
    return null;
  }

  public onModalClosed():void {
    if (!this.handler.inEditMode) {
      this.handler.deactivate(false);
    }
  }
}
