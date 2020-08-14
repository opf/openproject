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

import {Component, OnDestroy, OnInit} from "@angular/core";
import {TimezoneService} from "core-components/datetime/timezone.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {DatePickerModal} from "core-components/datepicker/datepicker.modal";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {take} from "rxjs/operators";
import {DateEditFieldComponent} from "core-app/modules/fields/edit/field-types/date-edit-field.component";
import {OpModalComponent} from "core-components/op-modals/op-modal.component";

@Component({
  template: `
    <input [value]="dates"
           (click)="handleClick()"
           type="text" />
  `
})
export class CombinedDateEditFieldComponent extends DateEditFieldComponent implements OnInit, OnDestroy {
  @InjectField() readonly timezoneService:TimezoneService;
  @InjectField() opModalService:OpModalService;

  dates:string = '';

  private modal:OpModalComponent;

  ngOnInit() {
    super.ngOnInit();

    this.handler
      .$onUserActivate
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(() => {
        this.showDatePickerModal();
      });
  }

  ngOnDestroy() {
    super.ngOnDestroy();
    this.modal?.closeMe();
  }

  public handleClick() {
    this.showDatePickerModal();
  }

  private showDatePickerModal():void {
    const modal = this.modal = this
      .opModalService
      .show(DatePickerModal, this.injector, { changeset: this.change, fieldName: this.name });

    setTimeout(() => {
      const modalElement = jQuery(modal.elementRef.nativeElement).find('.datepicker-modal');
      const field = jQuery(this.elementRef.nativeElement);
      modal.reposition(modalElement, field);
    });

    modal
      .onDataUpdated
      .subscribe((dates:string) => {
        this.dates = dates;
        this.cdRef.detectChanges();
      });

    modal
      .closingEvent
      .pipe(take(1))
      .subscribe(() => {
        this.handler.handleUserSubmit();
      });
  }
}
