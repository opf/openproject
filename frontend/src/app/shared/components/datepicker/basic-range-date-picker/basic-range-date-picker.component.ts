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
  computed,
  debounced,
  effect,
  ElementRef,
  forwardRef,
  HostBinding,
  inject,
  Injector,
  input,
  linkedSignal,
  OnInit,
  output,
  Resource,
  untracked,
  ViewChild,
  ViewEncapsulation,
  WritableSignal,
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
import { DeviceService } from 'core-app/core/browser/device.service';
import {
  booleanAttributeOr,
  jsonAttribute,
  optionalStringAttribute,
  stringAttribute,
} from 'core-app/shared/helpers/angular/attribute-inputs';

export const rangeSeparator = '-';

function rangeValueAttribute(value:string|string[]|null|undefined):string[] {
  if (typeof value !== 'string') {
    return value ?? [];
  }

  if (value.trimStart().startsWith('[')) {
    const dates:unknown = JSON.parse(value);
    return Array.isArray(dates) ? dates.map(String) : [];
  }

  return value.split(/\s-\s/);
}

export const opBasicRangeDatePickerSelector = 'op-basic-range-date-picker';

@Component({
  selector: opBasicRangeDatePickerSelector,
  templateUrl: './basic-range-date-picker.component.html',
  styleUrls: [
    './basic-range-date-picker.component.sass',
  ],
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

  // Only laid out for the clear button when one is actually rendered, so that
  // the usages without it keep their previous layout. On mobile the native date
  // inputs clear themselves, so no button is rendered there.
  @HostBinding('class.op-basic-range-datepicker_clearable') get clearable():boolean {
    return this.showClearButton() && !this.mobile;
  }

  readonly valueChange = output<string[]>();

  private readonly defaultInputId = `flatpickr-input-${+(new Date())}`;

  readonly value = input<string[], string|string[]|null|undefined>([], { transform: rangeValueAttribute });

  readonly inputId = input(this.defaultInputId, { transform: stringAttribute(this.defaultInputId) });

  readonly name = input('', { transform: stringAttribute('') });

  readonly required = input(false, { transform: booleanAttributeOr(false) });

  readonly disabled = input(false, { transform: booleanAttributeOr(false) });

  readonly showClearButton = input(false, { transform: booleanAttributeOr(false) });

  readonly placeholder = input('', { transform: stringAttribute('') });

  readonly minimalDate = input<Date|null, Date|string|null|undefined>(null, {
    transform: (value) => (typeof value === 'string' ? new Date(value) : value ?? null),
  });

  readonly inputClassNames = input('', { transform: stringAttribute('') });

  readonly inDialog = input(undefined, { transform: optionalStringAttribute() });

  readonly inputAttrs = input<Record<string, string>, Record<string, string>|string|null|undefined>({}, { transform: jsonAttribute({}) });

  readonly currentValue = linkedSignal(() => this.value(), {
    equal: (a, b) => this.resolveDateArrayToString(a) === this.resolveDateArrayToString(b),
  });

  readonly stringValue = computed(() => this.resolveDateArrayToString(this.currentValue()));

  @ViewChild('input') input:ElementRef<HTMLInputElement>;

  datePickerInstance:DatePicker;

  text = {
    date: this.I18n.t('js.work_packages.properties.date'),
    placeholder: this.I18n.t('js.placeholders.default'),
    spacer: this.I18n.t('js.filter.value_spacer'),
    clear: this.I18n.t('js.button_clear'),
  };

  constructor() {
    afterRenderEffect(() => this.applyInputAttrs(this.inputAttrs()));
    this.commitWhenSettled(this.desktopDates, this.settledDesktopDates);
    this.commitWhenSettled(this.mobileDraft, this.settledMobileDraft);
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

  private readonly desktopDates = linkedSignal<string[], string[]|null>({ source: this.currentValue, computation: () => null });

  private readonly settledDesktopDates = debounced(this.desktopDates, 16);

  changeValueFromInputDebounced(value:string):void {
    this.desktopDates.set(this.resolveDateStringToArray(value));
  }

  private readonly mobileDraft = linkedSignal<string[], string[]|null>({ source: this.currentValue, computation: () => null });

  private readonly settledMobileDraft = debounced(this.mobileDraft, 16);

  changeMobileDateFromInput(index:0|1, date:string):void {
    const current = this.currentValue();
    const draft = [...(this.mobileDraft() ?? [current[0] || '', current[1] || ''])];
    draft[index] = date;
    this.mobileDraft.set(draft);
  }

  // Only the edit that is still pending may commit: a settled value can be
  // superseded or cancelled before this effect runs.
  private commitWhenSettled(pending:WritableSignal<string[]|null>, settled:Resource<string[]|null>):void {
    effect(() => {
      const dates = settled.value();
      if (dates !== null && dates === untracked(pending)) {
        untracked(() => {
          pending.set(null);
          this.changeValueFromInput(dates);
        });
      }
    });
  }

  changeValueFromInput(value:string|string[]) {
    const newDates = (typeof value === 'string') ? this.resolveDateStringToArray(value) : value;

    this.onChange(newDates);
    this.onTouched(newDates);
    this.currentValue.set(newDates);
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

  // Flatpickr keeps its own selection, so it has to be reset alongside the value
  // or it would restore the cleared dates the next time the calendar is opened.
  clearValue():void {
    this.cancelPendingInput();
    this.datePickerInstance?.clear();
    this.changeValueFromInput([]);
  }

  private cancelPendingInput():void {
    this.desktopDates.set(null);
    this.mobileDraft.set(null);
  }

  private initializeDatePicker() {
    this.datePickerInstance = new DatePicker(
      this.injector,
      this.inputId(),
      this.currentValue(),
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
        // eslint-disable-next-line @typescript-eslint/no-misused-promises
        onDayCreate: async (dObj:Date[], dStr:string, fp:flatpickr.Instance, dayElem:DayElement) => {
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

  writeValue(value:string[]|null):void {
    this.currentValue.set(value ?? []);
  }

  // No-ops until the ControlValueAccessor registers the real callbacks below.
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
