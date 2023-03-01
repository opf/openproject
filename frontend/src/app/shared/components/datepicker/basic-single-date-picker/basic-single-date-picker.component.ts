// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
  Injector,
  Input,
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
  parseDate,
} from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DatePicker } from '../datepicker';
import flatpickr from 'flatpickr';
import { DayElement } from 'flatpickr/dist/types/instance';
import { populateInputsFromDataset } from '../../dataset-inputs';
import { debounce } from 'lodash';
import { SpotDropModalTeleportationService } from 'core-app/spot/components/drop-modal/drop-modal-teleportation.service';

export const opBasicSingleDatePickerSelector = 'op-basic-single-date-picker';

@Component({
  selector: opBasicSingleDatePickerSelector,
  templateUrl: './basic-single-date-picker.component.html',
  styleUrls: ['../styles/datepicker.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => OpBasicSingleDatePickerComponent),
      multi: true,
    },
  ],
})
export class OpBasicSingleDatePickerComponent implements ControlValueAccessor, AfterViewInit {
  @Output('valueChange') valueChange = new EventEmitter();

  private _value = '';

  @Input() set value(newValue:string) {
    this._value = newValue;
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

  @Input() remoteFieldKey = null;

  @ViewChild('input') input:ElementRef;

  text = {
    date: this.I18n.t('js.work_packages.properties.date'),
    placeholder: this.I18n.t('js.placeholders.default'),
  };

  public datePickerInstance:DatePicker;

  constructor(
    readonly I18n:I18nService,
    readonly timezoneService:TimezoneService,
    readonly injector:Injector,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly spotDropModalTeleportationService:SpotDropModalTeleportationService,
  ) {
    populateInputsFromDataset(this);
  }

  ngAfterViewInit():void {
    this.initializeDatePicker();
  }

  changeValueFromInputDebounced = debounce(this.changeValueFromInput.bind(this), 16);

  changeValueFromInput(value:string) {
    this.valueChange.emit(value);
    this.onChange(value);
    this.writeValue(value);

    const date = parseDate(value || '');

    if (date !== '') {
      const dateString = this.timezoneService.formattedISODate(date);
      this.onTouched(dateString);
    }
    this.cdRef.detectChanges();
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
        mode: 'single',
        showMonths: 1,
        onReady: (_date:Date[], _datestr:string, instance:flatpickr.Instance) => {
          instance.calendarContainer.classList.add('op-datepicker-modal--flatpickr-instance');
        },
        onChange: (dates:Date[]) => {
          if (dates.length > 0) {
            const dateString = this.timezoneService.formattedISODate(dates[0]);
            this.writeValue(dateString);
            this.onChange(dateString);
            this.onTouched(dateString);
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

  writeValue(value:string):void {
    this.value = value;
  }

  onChange = (_:string):void => {};

  onTouched = (_:string):void => {};

  registerOnChange(fn:(_:string) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:string) => void):void {
    this.onTouched = fn;
  }
}
