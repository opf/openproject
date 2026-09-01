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

import { ChangeDetectionStrategy, Component, forwardRef, ViewEncapsulation } from '@angular/core';
import { NG_VALUE_ACCESSOR } from '@angular/forms';
import moment from 'moment-timezone';
import flatpickr from 'flatpickr';
import { DayElement } from 'flatpickr/dist/types/instance';
import { onDayCreate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { DatePicker } from '../datepicker';
import { OpBasicSingleDatePickerComponent } from '../basic-single-date-picker/basic-single-date-picker.component';

export const DISPLAY_DATETIME_FORMAT = 'YYYY-MM-DD HH:mm';
const MOBILE_DATETIME_FORMAT = 'YYYY-MM-DDTHH:mm';

@Component({
  selector: 'op-basic-single-datetime-picker',
  templateUrl: './basic-single-datetime-picker.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => OpBasicSingleDateTimePickerComponent),
      multi: true,
    },
  ],
  standalone: false,
})
export class OpBasicSingleDateTimePickerComponent extends OpBasicSingleDatePickerComponent {
  private changedSinceOpen = false;

  get displayValue():string {
    return this.formatValue(DISPLAY_DATETIME_FORMAT);
  }

  get mobileValue():string {
    return this.formatValue(MOBILE_DATETIME_FORMAT);
  }

  override changeValueFromInput(value:string):void {
    const parsed = moment.tz(
      value,
      [DISPLAY_DATETIME_FORMAT, MOBILE_DATETIME_FORMAT],
      true,
      this.timezoneService.userTimezone(),
    );

    if (parsed.isValid()) {
      const utcValue = parsed.utc().format();
      this.onTouched(utcValue);
      this.onChange(utcValue);
      this.writeValue(utcValue);
      this.valueChange.emit(utcValue);
    }
  }

  override writeValue(value:string):void {
    this.value = value;
    this.datePickerInstance?.setDates(this.displayValue);
  }

  protected override initializeDatePicker() {
    this.datePickerInstance = new DatePicker(
      this.injector,
      this.id,
      this.displayValue,
      {
        allowInput: true,
        enableTime: true,
        time_24hr: true,
        mode: 'single',
        showMonths: 1,
        dateFormat: 'Y-m-d H:i',
        onReady: (_date:Date[], _datestr:string, instance:flatpickr.Instance) => {
          instance.calendarContainer.classList.add('op-datepicker-modal--flatpickr-instance');
        },
        onChange: (_:Date[], dateStr:string) => {
          if (dateStr.length > 0) {
            this.changedSinceOpen = true;
            this.changeValueFromInput(dateStr);
          }

          this.cdRef.detectChanges();
        },
        onOpen: () => {
          this.changedSinceOpen = false;
          this.sentCalendarToTopLayer();
        },
        onClose: () => {
          if (this.changedSinceOpen) {
            this.picked.emit();
          }
        },
        onDayCreate: (_dObj:Date[], _dStr:string, _fp:flatpickr.Instance, dayElem:DayElement) => {
          void (async () => {
            onDayCreate(
              dayElem,
              true,
              await this.datePickerInstance?.isNonWorkingDay(dayElem.dateObj),
              !!this.minimalDate && dayElem.dateObj <= this.minimalDate,
            );
          })();
        },
        static: false,
        appendTo: this.appendToBodyOrDialog(),
      },
      this.input.nativeElement,
    );
  }

  private formatValue(format:string):string {
    if (!this.value) {
      return '';
    }

    return this.timezoneService.parseDatetime(this.value).format(format);
  }
}
