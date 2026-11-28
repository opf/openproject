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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  afterRenderEffect,
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  forwardRef,
  inject,
  Injector,
  input,
  linkedSignal,
  OnDestroy,
  OnInit,
  Output,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { onDayCreate, validDate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DatePicker } from '../datepicker';
import flatpickr from 'flatpickr';
import { DayElement } from 'flatpickr/dist/types/instance';
import { DeviceService } from 'core-app/core/browser/device.service';
import {
  booleanAttributeOr,
  jsonAttribute,
  optionalStringAttribute,
  stringAttribute,
} from 'core-app/shared/helpers/angular/attribute-inputs';

@Component({
  selector: 'op-basic-single-date-picker',
  templateUrl: './basic-single-date-picker.component.html',
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

  private readonly defaultInputId = `flatpickr-input-${+(new Date())}`;

  readonly value = input('', { transform: stringAttribute('') });

  readonly inputId = input(this.defaultInputId, { transform: stringAttribute(this.defaultInputId) });

  readonly name = input('', { transform: stringAttribute('') });

  readonly required = input(false, { transform: booleanAttributeOr(false) });

  readonly disabled = input(false, { transform: booleanAttributeOr(false) });

  readonly placeholder = input('', { transform: stringAttribute('') });

  readonly minimalDate = input<Date|null, Date|string|null|undefined>(null, {
    transform: (value) => (typeof value === 'string' ? new Date(value) : value ?? null),
  });

  readonly inputClassNames = input('', { transform: stringAttribute('') });

  readonly remoteFieldKey = input(undefined, { transform: optionalStringAttribute() });

  readonly inDialog = input(undefined, { transform: optionalStringAttribute() });

  readonly inputAttrs = input<Record<string, string>, Record<string, string>|string|null|undefined>({}, { transform: jsonAttribute({}) });

  readonly currentValue = linkedSignal<string|null>(() => this.value());

  @ViewChild('input') input:ElementRef<HTMLInputElement>;

  mobile = false;

  text = {
    date: this.I18n.t('js.work_packages.properties.date'),
    placeholder: this.I18n.t('js.placeholders.default'),
  };

  public datePickerInstance:DatePicker;

  constructor() {
    afterRenderEffect(() => this.applyInputAttrs(this.inputAttrs()));
  }

  ngOnInit() {
    this.mobile = this.deviceService.isMobile;
  }

  ngAfterViewInit():void {
    if (!this.mobile) {
      this.initializeDatePicker();
    }
  }

  private applyInputAttrs(attrs:Record<string, string>):void {
    const el = this.input?.nativeElement
      ?? this.elementRef.nativeElement.querySelector<HTMLInputElement>(`input[id="${CSS.escape(this.inputId())}"]`);
    if (el) {
      Object.entries(attrs).forEach(([key, val]) => el.setAttribute(key, val));
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
      this.inputId(),
      this.currentValue() ?? '',
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
        // eslint-disable-next-line @typescript-eslint/no-misused-promises
        onDayCreate: async (_dObj:Date[], _dStr:string, _fp:flatpickr.Instance, dayElem:DayElement) => {
          const minimalDate = this.minimalDate();
          onDayCreate(
            dayElem,
            true,
            await this.datePickerInstance?.isNonWorkingDay(dayElem.dateObj),
            !!minimalDate && dayElem.dateObj <= minimalDate,
          );
        },
        static: false,
        appendTo: this.appendToBodyOrDialog(),
      },
      this.input.nativeElement,
    );
  }

  writeValue(value:string|null):void {
    this.currentValue.set(value);
    this.datePickerInstance?.setDates(value ?? '');
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
    if (!this.datePickerInstance.isOpen || !this.inDialog()) {
      return;
    }

    const calendarContainer = this.datePickerInstance.datepickerInstance.calendarContainer;
    calendarContainer.setAttribute('popover', '');
    calendarContainer.showPopover();
    calendarContainer.style.marginTop = '0';
  }

  private appendToBodyOrDialog():HTMLElement|undefined {
    const inDialog = this.inDialog();
    if (inDialog) {
      return document.getElementById(inDialog)!;
    }

    return undefined;
  }
}
