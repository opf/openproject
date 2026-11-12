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
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  forwardRef,
  inject,
  Injector,
  Input,
  OnDestroy,
  Output,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import flatpickr from 'flatpickr';
import { DayElement } from 'flatpickr/dist/types/instance';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { onDayCreate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { isoToWallClockDate, wallClockDateToISO } from 'core-common/local-datetime';
import { DatePicker } from '../datepicker';
import { populateInputsFromDataset } from '../../dataset-inputs';

// The submitted input holds the ISO value, while the visible alt input shows the user's format.
const ISO_FORMAT = 'ISO';
const DISPLAY_FORMAT = 'DISPLAY';

@Component({
  selector: 'op-basic-single-datetime-picker',
  templateUrl: './basic-single-datetime-picker.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => OpBasicSingleDatetimePickerComponent),
      multi: true,
    },
  ],
  standalone: false,
})
export class OpBasicSingleDatetimePickerComponent implements ControlValueAccessor, AfterViewInit, OnDestroy {
  readonly timezoneService = inject(TimezoneService);
  readonly injector = inject(Injector);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  @Output() valueChange = new EventEmitter<string>();

  @Output() picked = new EventEmitter<void>();

  @Input() value = '';

  @Input() id = `flatpickr-input-${+(new Date())}`;

  @Input() name = '';

  @Input() required = false;

  @Input() set disabled(disabled:boolean) {
    this._disabled = disabled;
    this.applyDisabled();
  }

  get disabled():boolean {
    return this._disabled;
  }

  @Input() placeholder = '';

  @Input() inputClassNames = '';

  @Input() inDialog:string;

  @Input() dataAction = '';

  @Input() set inputAttrs(attrs:Record<string, string> | null) {
    this._inputAttrs = attrs ?? {};
    this.applyInputAttrs();
  }

  @ViewChild('input') input:ElementRef<HTMLInputElement>;

  public datePickerInstance:DatePicker;

  private _inputAttrs:Record<string, string> = {};

  private _disabled = false;

  private closedByEscape = false;

  constructor() {
    populateInputsFromDataset(this);
  }

  ngAfterViewInit():void {
    this.initializeDatePicker();
    this.applyInputAttrs();
  }

  private applyInputAttrs():void {
    const el = this.input?.nativeElement;
    if (el) {
      Object.entries(this._inputAttrs).forEach(([key, val]) => el.setAttribute(key, val));
    }
  }

  ngOnDestroy():void {
    this.datePickerInstance?.destroy();
  }

  writeValue(value:string|null):void {
    this.value = value ?? '';

    if (this.value) {
      this.datePickerInstance?.setDates(this.value);
    } else {
      this.datePickerInstance?.clear();
    }
  }

  setDisabledState(disabled:boolean):void {
    this.disabled = disabled;
  }

  onChange = (_:string):void => undefined;

  onTouched = (_:string):void => undefined;

  registerOnChange(fn:(_:string) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:string) => void):void {
    this.onTouched = fn;
  }

  // In a dialog, the calendar has to be in the top layer as well. Clicking the input counts as a click
  // on the backdrop and removes the calendar from the top layer, see OpBasicSingleDatePickerComponent.
  private sendCalendarToTopLayer():void {
    if (!this.datePickerInstance?.isOpen || !this.inDialog) {
      return;
    }

    const calendarContainer = this.datePickerInstance.datepickerInstance.calendarContainer;
    calendarContainer.setAttribute('popover', '');
    calendarContainer.showPopover();
    calendarContainer.style.marginTop = '0';
  }

  private initializeDatePicker():void {
    this.datePickerInstance = new DatePicker(
      this.injector,
      this.id,
      this.value || '',
      {
        enableTime: true,
        time_24hr: this.timezoneService.uses24HourClock(),
        allowInput: true,
        altInput: true,
        altInputClass: ['spot-input', this.inputClassNames].join(' '),
        dateFormat: ISO_FORMAT,
        altFormat: DISPLAY_FORMAT,
        formatDate: (date:Date, format:string) => this.formatDate(date, format),
        parseDate: (text:string, format:string) => this.parseDate(text, format)!,
        onReady: (_dates:Date[], _dateStr:string, instance:flatpickr.Instance) => {
          instance.calendarContainer.classList.add('op-datepicker-modal--flatpickr-instance');
          this.setUpVisibleInput(instance);
          this.applyDisabled();
        },
        onChange: (dates:Date[]) => {
          this.updateValue(dates);
        },
        onOpen: () => {
          this.closedByEscape = false;
          this.sendCalendarToTopLayer();
        },
        // Clicking outside applies typed text without triggering onChange, so the value is taken over on close.
        onClose: (dates:Date[]) => {
          this.updateValue(dates);

          if (!this.closedByEscape) {
            this.picked.emit();
          }
        },
        onDayCreate: (_dates:Date[], _dateStr:string, _instance:flatpickr.Instance, dayElem:DayElement) => {
          void this.markNonWorkingDay(dayElem);
        },
        static: false,
        appendTo: this.appendToBodyOrDialog(),
      },
      this.input.nativeElement,
    );
  }

  private updateValue(dates:Date[]):void {
    const value = dates[0] ? wallClockDateToISO(dates[0], this.timezoneService.userTimezone()) ?? '' : '';
    if (this.isSameInstant(value, this.value)) {
      return;
    }

    this.value = value;
    this.onTouched(value);
    this.onChange(value);
    this.valueChange.emit(value);
  }

  private isSameInstant(first:string, second:string):boolean {
    return first === second || (!!first && !!second && Date.parse(first) === Date.parse(second));
  }

  private formatDate(date:Date, format:string):string {
    const value = wallClockDateToISO(date, this.timezoneService.userTimezone()) ?? '';

    return format === DISPLAY_FORMAT ? this.timezoneService.formattedDatetime(value) : value;
  }

  private parseDate(text:string, format:string):Date|undefined {
    const value = format === DISPLAY_FORMAT ? this.timezoneService.parseFormattedDatetime(text) : text;
    if (!value) {
      return undefined;
    }

    return isoToWallClockDate(value, this.timezoneService.userTimezone()) ?? undefined;
  }

  private async markNonWorkingDay(dayElem:DayElement):Promise<void> {
    onDayCreate(dayElem, true, await this.datePickerInstance?.isNonWorkingDay(dayElem.dateObj), false);
  }

  // flatpickr hides the original input, so labels pointing to the id have to reach the visible one.
  private setUpVisibleInput(instance:flatpickr.Instance):void {
    if (instance.altInput) {
      instance.input.id = `${this.id}-value`;
      instance.altInput.id = this.id;
      instance.altInput.addEventListener('click', () => this.sendCalendarToTopLayer());
      instance.altInput.addEventListener('keydown', (event:KeyboardEvent) => {
        if (event.key === 'Escape') {
          this.closedByEscape = true;
        }
      });
    }
  }

  private applyDisabled():void {
    const altInput = this.datePickerInstance?.datepickerInstance?.altInput;
    if (altInput) {
      altInput.disabled = this.disabled;
    }
  }

  private appendToBodyOrDialog():HTMLElement|undefined {
    if (this.inDialog) {
      return document.querySelector<HTMLElement>(`#${this.inDialog}`)!;
    }

    return undefined;
  }
}
