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

import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, EventEmitter, forwardRef, HostBinding, Injector, Input, OnInit, Output, ViewChild, ViewEncapsulation, inject } from '@angular/core';
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
import { debounce } from 'lodash-es';
import { DeviceService } from 'core-app/core/browser/device.service';

export const rangeSeparator = '-';

export const opBasicRangeDatePickerSelector = 'op-basic-range-date-picker';

@Component({
  selector: opBasicRangeDatePickerSelector,
  templateUrl: './basic-range-date-picker.component.html',
  styleUrls: [
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
  standalone: false,
})
export class OpBasicRangeDatePickerComponent implements OnInit, ControlValueAccessor, AfterViewInit {
  readonly I18n = inject(I18nService);
  readonly timezoneService = inject(TimezoneService);
  readonly injector = inject(Injector);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly deviceService = inject(DeviceService);

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

  @Input() placeholder = '';

  @Input() minimalDate:Date|null = null;

  @Input() inputClassNames = '';

  @Input() inDialog:string;

  @Input() dataAction = '';

  @Input() set inputAttrs(attrs:Record<string, string> | null) {
    this._inputAttrs = attrs ?? {};
    this.applyInputAttrs();
  }

  private _inputAttrs:Record<string, string> = {};

  @ViewChild('input') input:ElementRef<HTMLInputElement>;

  stringValue = '';

  datePickerInstance:DatePicker;

  text = {
    date: this.I18n.t('js.work_packages.properties.date'),
    placeholder: this.I18n.t('js.placeholders.default'),
    spacer: this.I18n.t('js.filter.value_spacer'),
  };

  constructor() {
    populateInputsFromDataset(this);
  }

  ngOnInit() {
    this.mobile = this.deviceService.isMobile;
  }

  ngAfterViewInit():void {
    if (!this.mobile) {
      this.initializeDatePicker();
    }
    this.applyInputAttrs();
  }

  private applyInputAttrs():void {
    const el = this.input?.nativeElement
      ?? this.elementRef.nativeElement.querySelector<HTMLInputElement>(`input[id="${this.id}"]`);
    if (el) {
      Object.entries(this._inputAttrs).forEach(([key, val]) => el.setAttribute(key, val));
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
    if (!this.datePickerInstance?.isOpen) {
      this.datePickerInstance?.show();
      this.sentCalendarToTopLayer();
    }
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
        onOpen: () => {
          this.sentCalendarToTopLayer();
        },
        onDayCreate: async (dObj:Date[], dStr:string, fp:flatpickr.Instance, dayElem:DayElement) => {
          onDayCreate(
            dayElem,
            true,
            await this.datePickerInstance?.isNonWorkingDay(dayElem.dateObj),
            !!this.minimalDate && dayElem.dateObj <= this.minimalDate,
          );
        },
        static: false,
        appendTo: this.appendToBodyOrDialog(),
      },
      this.input.nativeElement,
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

  private resolveDateStringToArray(dates:string):string[] {
    return dates.split(` ${rangeSeparator} `).map((date) => date.trim());
  }

  private resolveDateArrayToString(dates:string[]):string {
    return dates.join(` ${rangeSeparator} `);
  }

  // In case the date picker is opened in a dialog, it needs to be in the top layer
  // since the dialog is also there. This method is called in two cases:
  // 1. When the date picker is opened
  // 2. When the date picker is already opened and the user clicks on the input
  // The later is necessary as otherwise the date picker would be removed from the top layer
  // when the user clicks on the input. That is because the input is not part of the date picker
  // so clicking on it would be considered a click on the backdrop which removes an item from
  // the top layer again.
  public sentCalendarToTopLayer() {
    if (!this.datePickerInstance.isOpen || !this.inDialog) {
      return;
    }

    const calendarContainer = this.datePickerInstance.datepickerInstance.calendarContainer;
    calendarContainer.setAttribute('popover', '');
    calendarContainer.showPopover();
    calendarContainer.style.marginTop = '0';
  }

  private appendToBodyOrDialog():HTMLElement|undefined {
    if (this.inDialog) {
      return document.querySelector<HTMLElement>(`#${this.inDialog}`)!;
    }

    return undefined;
  }
}
