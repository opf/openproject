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

import { AfterViewInit, Component, ElementRef, EventEmitter, Input, OnDestroy, Output, ViewChild } from '@angular/core';
import { ConfigurationService } from 'core-app/modules/common/config/configuration.service';
import { TimezoneService } from 'core-components/datetime/timezone.service';
import { DatePicker } from "core-app/modules/common/op-date-picker/datepicker";
import { DebouncedEventEmitter } from "core-components/angular/debounced-event-emitter";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { componentDestroyed } from "@w11k/ngx-componentdestroyed";
import { keyCodes } from "core-app/modules/common/keyCodes.enum";
import { Instance } from "flatpickr/dist/types/instance";

@Component({
  selector: 'op-date-picker',
  templateUrl: './op-date-picker.component.html'
})
export class OpDatePickerComponent extends UntilDestroyedMixin implements OnDestroy, AfterViewInit {
  @Output() public onChange = new DebouncedEventEmitter<string>(componentDestroyed(this));
  @Output() public onCancel = new EventEmitter<string>();

  @Input() public initialDate = '';
  @Input() public appendTo?:HTMLElement = document.body;
  @Input() public classes = '';
  @Input() public id = '';
  @Input() public name = '';
  @Input() public required = false;
  @Input() public size = 20;
  @Input() public focus = false;
  @Input() public disabled = false;

  @ViewChild('dateInput') dateInput:ElementRef;

  private datePickerInstance:DatePicker;

  public constructor(private elementRef:ElementRef,
                     private ConfigurationService:ConfigurationService,
                     private timezoneService:TimezoneService) {
    super();

    if (!this.id) {
      this.id = 'datepicker-input-' + Math.floor(Math.random() * 1000).toString(3);
    }
  }

  ngAfterViewInit():void {
    this.initializeDatepicker();
  }

  ngOnDestroy() {
    this.datePickerInstance && this.datePickerInstance.destroy();
  }

  openOnClick() {
    if (!this.disabled) {
      this.datePickerInstance.show();
    }
  }

  onInputChange(_event:KeyboardEvent) {
    if (this.isEmpty()) {
      this.datePickerInstance.clear();
    } else if (this.inputIsValidDate()) {
      this.onChange.emit(this.currentValue);
    }
  }

  closeOnOutsideClick(event:any) {
    if (!(event.relatedTarget &&
      this.datePickerInstance.datepickerInstance.calendarContainer.contains(event.relatedTarget))) {
      this.datePickerInstance.hide();
    }
  }

  private isEmpty():boolean {
    return this.currentValue.trim() === '';
  }

  private get currentValue():string {
    return this.inputElement?.value || '';
  }

  private get inputElement():HTMLInputElement {
    return this.dateInput.nativeElement;
  }

  private inputIsValidDate():boolean {
    return this.currentValue.match(/\d{4}-\d{2}-\d{2}/) !== null;
  }

  private initializeDatepicker() {
    const options:any = {
      allowInput: true,
      appendTo: this.appendTo,
      onChange:(selectedDates:Date[], dateStr:string) => {
        const val:string = dateStr;

        if (this.isEmpty()) {
          return;
        }

        this.inputElement.value = val;
        this.onChange.emit(val);
      },
      onKeyDown: (selectedDates:Date[], dateStr:string, instance:Instance, data:KeyboardEvent) => {
        if (data.which == keyCodes.ESCAPE) {
          this.onCancel.emit();
        }
      }
    };

    let initialValue;
    if (this.isEmpty && this.initialDate) {
      initialValue = this.timezoneService.parseISODate(this.initialDate).toDate();
    } else {
      initialValue = this.currentValue;
    }

    this.datePickerInstance = new DatePicker(
      '#' + this.id,
      initialValue,
      options
    );
  }
}
