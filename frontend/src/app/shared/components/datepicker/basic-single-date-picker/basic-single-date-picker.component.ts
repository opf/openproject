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

import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, EventEmitter, forwardRef, Injector, Input, OnDestroy, OnInit, Output, ViewChild, ViewEncapsulation, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { onDayCreate, validDate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DatePicker } from '../datepicker';
import flatpickr from 'flatpickr';
import { DayElement } from 'flatpickr/dist/types/instance';
import { populateInputsFromDataset } from '../../dataset-inputs';
import { DeviceService } from 'core-app/core/browser/device.service';

@Component({
  selector: 'op-basic-single-date-picker',
  templateUrl: './basic-single-date-picker.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => OpBasicSingleDatePickerComponent),
      multi: true,
    },
  ],
  standalone: false,
})
export class OpBasicSingleDatePickerComponent implements ControlValueAccessor, OnInit, AfterViewInit, OnDestroy {
  readonly I18n = inject(I18nService);
  readonly timezoneService = inject(TimezoneService);
  readonly injector = inject(Injector);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly deviceService = inject(DeviceService);

  @Output() valueChange = new EventEmitter();

  @Output() picked = new EventEmitter();

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

  @Input() placeholder = '';

  @Input() minimalDate:Date|null = null;

  @Input() inputClassNames = '';

  @Input() remoteFieldKey = null;

  @Input() inDialog:string;

  @Input() dataAction = '';

  @Input() set inputAttrs(attrs:Record<string, string> | null) {
    this._inputAttrs = attrs ?? {};
    this.applyInputAttrs();
  }

  private _inputAttrs:Record<string, string> = {};

  @ViewChild('input') input:ElementRef<HTMLInputElement>;

  mobile = false;

  text = {
    date: this.I18n.t('js.work_packages.properties.date'),
    placeholder: this.I18n.t('js.placeholders.default'),
  };

  public datePickerInstance:DatePicker;

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

  ngOnDestroy():void {
    this.datePickerInstance?.destroy();
  }

  changeValueFromInput(value:string) {
    if (validDate(value)) {
      this.onTouched(value);
      this.onChange(value);
      this.writeValue(value);
      this.datePickerInstance?.setDates(value);
      this.valueChange.emit(value);
    }
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
        mode: 'single',
        showMonths: 1,
        onReady: (_date:Date[], _datestr:string, instance:flatpickr.Instance) => {
          instance.calendarContainer.classList.add('op-datepicker-modal--flatpickr-instance');
        },
        onChange: (_:Date[], dateStr:string) => {
          this.writeValue(dateStr);
          if (dateStr.length > 0) {
            const dateString = this.timezoneService.formattedISODate(dateStr);
            this.valueChange.emit(dateString);
            this.onTouched(dateString);
            this.onChange(dateString);
            this.writeValue(dateString);
            this.picked.emit();
          }

          this.cdRef.detectChanges();
        },
        onOpen: () => {
          this.sentCalendarToTopLayer();
        },
        onDayCreate: async (_dObj:Date[], _dStr:string, _fp:flatpickr.Instance, dayElem:DayElement) => {
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

  writeValue(value:string):void {
    this.value = value;
    this.datePickerInstance?.setDates(this.value);
  }

  onChange = (_:string):void => {};

  onTouched = (_:string):void => {};

  registerOnChange(fn:(_:string) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:string) => void):void {
    this.onTouched = fn;
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
