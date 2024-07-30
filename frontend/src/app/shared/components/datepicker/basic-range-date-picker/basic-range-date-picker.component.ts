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

import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  forwardRef,
  HostBinding,
  Injector,
  Input,
  OnInit,
  Output,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ControlValueAccessor,
  NG_VALUE_ACCESSOR,
} from '@angular/forms';
import {
  onDayCreate,
  validDate,
} from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DatePicker } from '../datepicker';
import flatpickr from 'flatpickr';
import { DayElement } from 'flatpickr/dist/types/instance';
import { populateInputsFromDataset } from '../../dataset-inputs';
import { debounce } from 'lodash';
import { DeviceService } from 'core-app/core/browser/device.service';

export const rangeSeparator = '-';

export const opBasicRangeDatePickerSelector = 'op-basic-range-date-picker';

@Component({
  selector: opBasicRangeDatePickerSelector,
  templateUrl: './basic-range-date-picker.component.html',
  styleUrls: [
    '../styles/datepicker.modal.sass',
    './basic-range-date-picker.component.sass',
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => OpBasicRangeDatePickerComponent),
      multi: true,
    },
  ],
})
export class OpBasicRangeDatePickerComponent implements OnInit, ControlValueAccessor, AfterViewInit {
  @HostBinding('class.op-basic-range-datepicker') className = true;

  @HostBinding('class.op-basic-range-datepicker_mobile') mobile = false;

  @Output() valueChange = new EventEmitter();

  private _value:string[] = [];

  @Input() set value(newValue:string|string[]) {
    if (typeof newValue === 'string') {
      this._value = newValue.split(/\s-\s/);
    } else {
      this._value = newValue;
    }

    this.stringValue = this.resolveDateArrayToString(this._value);
  }

  get value() {
    return this._value;
  }

  @Input() id = `flatpickr-input-${+(new Date())}`;

  @Input() name = '';

  @Input() required = false;

  @Input() disabled = false;

  @Input() minimalDate:Date|null = null;

  @Input() inputClassNames = '';

  @ViewChild('input') input:ElementRef;

  stringValue = '';

  datePickerInstance:DatePicker;

  text = {
    date: this.I18n.t('js.work_packages.properties.date'),
    placeholder: this.I18n.t('js.placeholders.default'),
    spacer: this.I18n.t('js.filter.value_spacer'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly timezoneService:TimezoneService,
    readonly injector:Injector,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly deviceService:DeviceService,
  ) {
    populateInputsFromDataset(this);
  }

  ngOnInit() {
    this.mobile = this.deviceService.isMobile;
  }

  ngAfterViewInit():void {
    if (!this.mobile) {
      this.initializeDatePicker();
    }
  }

  changeValueFromInputDebounced = debounce(this.changeValueFromInput.bind(this), 16);

  changeValueFromInput(value:string|string[]) {
    const newDates = (typeof value === 'string') ? this.resolveDateStringToArray(value) : value;

    this.onChange(newDates);
    this.onTouched(newDates);
    this.writeValue(newDates);
    this.cdRef.detectChanges();

    if (newDates.find((el) => !validDate(el))) {
      return;
    }

    this.valueChange.emit(newDates);
  }

  showDatePicker():void {
    this.datePickerInstance?.show();
  }

  private initializeDatePicker() {
    this.datePickerInstance = new DatePicker(
      this.injector,
      this.id,
      this.value || '',
      {
        allowInput: true,
        mode: 'range',
        showMonths: 2,
        onReady: (_date:Date[], _datestr:string, instance:flatpickr.Instance) => {
          instance.calendarContainer.classList.add('op-datepicker-modal--flatpickr-instance');
        },
        onChange: (dates:Date[], dateStr:string) => {
          if (dates.length === 2) {
            const value = this.resolveDateStringToArray(dateStr);
            this.writeValue(value);
            this.onChange(value);
            this.onTouched(value);
          }

          this.cdRef.detectChanges();
        },
        onDayCreate: async (dObj:Date[], dStr:string, fp:flatpickr.Instance, dayElem:DayElement) => {
          onDayCreate(
            dayElem,
            true,
            await this.datePickerInstance?.isNonWorkingDay(dayElem.dateObj),
            !!this.minimalDate && dayElem.dateObj <= this.minimalDate,
          );
        },
      },
      this.input.nativeElement as HTMLInputElement,
    );
  }

  writeValue(value:string[]):void {
    this.value = value;
  }

  onChange = (_:string[]):void => {};

  onTouched = (_:string[]):void => {};

  registerOnChange(fn:(_:string[]) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:string[]) => void):void {
    this.onTouched = fn;
  }

  // eslint-disable-next-line class-methods-use-this
  private resolveDateStringToArray(dates:string):string[] {
    return dates.split(` ${rangeSeparator} `).map((date) => date.trim());
  }

  // eslint-disable-next-line class-methods-use-this
  private resolveDateArrayToString(dates:string[]):string {
    return dates.join(` ${rangeSeparator} `);
  }
}
