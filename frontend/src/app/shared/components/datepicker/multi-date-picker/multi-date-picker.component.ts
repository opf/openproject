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
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  forwardRef,
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
  areDatesEqual,
  mappedDate,
  onDayCreate,
  parseDate,
  setDates,
  validDate,
} from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DatePicker } from '../datepicker';
import flatpickr from 'flatpickr';
import { DayElement } from 'flatpickr/dist/types/instance';
import {
  ActiveDateChange,
  DateFields,
  DateKeys,
} from '../wp-multi-date-form/wp-multi-date-form.component';
import {
  fromEvent,
  merge,
  Observable,
  Subject,
} from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  debounceTime,
  filter,
  map,
} from 'rxjs/operators';
import { DeviceService } from 'core-app/core/browser/device.service';
import { DateOption } from 'flatpickr/dist/types/options';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { SpotDropModalTeleportationService } from 'core-app/spot/components/drop-modal/drop-modal-teleportation.service';

@Component({
  selector: 'op-multi-date-picker',
  templateUrl: './multi-date-picker.component.html',
  styleUrls: ['../styles/datepicker.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => OpMultiDatePickerComponent),
      multi: true,
    },
  ],
})
export class OpMultiDatePickerComponent extends UntilDestroyedMixin implements OnInit, ControlValueAccessor {
  @ViewChild('modalContainer') modalContainer:ElementRef<HTMLElement>;

  @ViewChild('flatpickrTarget') flatpickrTarget:ElementRef;

  @Input() id = `flatpickr-input-${+(new Date())}`;

  @Input() name = '';

  @Input() fieldName = '';

  @Input() value:string[] = [];

  @Input() applyLabel:string;

  private _opened = false;

  @Input() set opened(opened:boolean) {
    if (this._opened === !!opened) {
      return;
    }

    this._opened = !!opened;

    if (this._opened) {
      this.initializeDatepickerAfterOpen();
    } else {
      this.datePickerInstance?.destroy();
      this.closed.emit();
    }
  }

  get opened() {
    return this._opened;
  }

  @Output() valueChange = new EventEmitter();

  @Output('closed') closed = new EventEmitter();

  text = {
    apply: this.I18n.t('js.modals.button_apply'),
    cancel: this.I18n.t('js.button_cancel'),
    startDate: this.I18n.t('js.work_packages.properties.startDate'),
    endDate: this.I18n.t('js.work_packages.properties.dueDate'),
    placeholder: this.I18n.t('js.placeholders.default'),
    today: this.I18n.t('js.label_today'),
    days: (count:number):string => this.I18n.t('js.units.day', { count }),
    ignoreNonWorkingDays: {
      title: this.I18n.t('js.work_packages.datepicker_modal.ignore_non_working_days.title'),
    },
  };

  get datesString():string {
    if (this.value?.[0] && this.value?.[1]) {
      return `${this.value[0]} - ${this.value[1]}`;
    }

    return this.text.placeholder;
  }

  ignoreNonWorkingDays = true;

  currentlyActivatedDateField:DateFields;

  htmlId = '';

  dates:{ [key in DateKeys]:string|null } = {
    start: null,
    end: null,
  };

  // Manual changes from the inputs to start and end dates
  startDateChanged$ = new Subject<string>();

  startDateDebounced$:Observable<ActiveDateChange> = this.debouncedInput(this.startDateChanged$, 'start');

  endDateChanged$ = new Subject<string>();

  endDateDebounced$:Observable<ActiveDateChange> = this.debouncedInput(this.endDateChanged$, 'end');

  // Manual changes to the datepicker, with information which field was active
  datepickerChanged$ = new Subject<ActiveDateChange>();

  ignoreNonWorkingDaysWritable = true;

  private datePickerInstance:DatePicker;

  constructor(
    readonly injector:Injector,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly timezoneService:TimezoneService,
    readonly deviceService:DeviceService,
    readonly weekdayService:WeekdayService,
    readonly focusHelper:FocusHelperService,
    readonly spotDropModalTeleportationService:SpotDropModalTeleportationService,
  ) {
    super();

    merge(
      this.startDateDebounced$,
      this.endDateDebounced$,
      this.datepickerChanged$,
    )
      .pipe(
        this.untilDestroyed(),
        filter(() => !!this.datePickerInstance),
      )
      .subscribe(([field, update]) => {
        // When clearing the one date, clear the others as well
        if (update !== null) {
          this.handleSingleDateUpdate(field, update);
        }

        this.cdRef.detectChanges();
      });
  }

  ngOnInit():void {
    this.applyLabel = this.applyLabel || this.text.apply;
    this.htmlId = `wp-datepicker-${this.fieldName}`;
    this.dates.start = this.value?.[0];
    this.dates.end = this.value?.[1];

    this.setCurrentActivatedField(this.initialActivatedField);
  }

  onInputClick(event:MouseEvent) {
    event.stopPropagation();
  }

  close():void {
    this.opened = false;
  }

  changeNonWorkingDays():void {
    this.initializeDatepicker();
    this.cdRef.detectChanges();
  }

  save($event:Event):void {
    $event.preventDefault();
    const value = [
      this.dates.start || '',
      this.dates.end || '',
    ];
    this.value = value;
    this.valueChange.emit(value);
    this.onChange(value);
    this.close();
  }

  updateDate(key:DateKeys, val:string|null):void {
    if ((val === null || validDate(val)) && this.datePickerInstance) {
      this.dates[key] = mappedDate(val);
      const dateValue = parseDate(val || '') || undefined;
      this.enforceManualChangesToDatepicker(dateValue);
      this.cdRef.detectChanges();
    }
  }

  setCurrentActivatedField(val:DateFields):void {
    this.currentlyActivatedDateField = val;
  }

  toggleCurrentActivatedField():void {
    this.currentlyActivatedDateField = this.currentlyActivatedDateField === 'start' ? 'end' : 'start';
  }

  isStateOfCurrentActivatedField(val:DateFields):boolean {
    return this.currentlyActivatedDateField === val;
  }

  setToday(key:DateKeys):void {
    this.datepickerChanged$.next([key, new Date()]);

    const nextActive = key === 'start' ? 'end' : 'start';
    this.setCurrentActivatedField(nextActive);
  }

  showFieldAsActive(field:DateFields):boolean {
    return this.isStateOfCurrentActivatedField(field);
  }

  private initializeDatepickerAfterOpen():void {
    this.spotDropModalTeleportationService
      .afterRenderOnce$(true)
      .subscribe(() => {
        this.initializeDatepicker();
      });
  }

  private initializeDatepicker(minimalDate?:Date|null) {
    this.datePickerInstance?.destroy();
    this.datePickerInstance = new DatePicker(
      this.injector,
      this.id,
      [this.dates.start || '', this.dates.end || ''],
      {
        mode: 'range',
        showMonths: this.deviceService.isMobile ? 1 : 2,
        inline: true,
        onReady: (_date, _datestr, instance) => {
          instance.calendarContainer.classList.add('op-datepicker-modal--flatpickr-instance');

          this.ensureHoveredSelection(instance.calendarContainer);
        },
        onChange: (dates:Date[], _datestr, instance) => {
          this.onTouched();

          if (dates.length === 2) {
            this.setDates(dates[0], dates[1]);
            this.toggleCurrentActivatedField();
            this.cdRef.detectChanges();
            return;
          }

          // Update with the same flow as entering a value
          const { latestSelectedDateObj } = instance as { latestSelectedDateObj:Date };
          const activeField = this.currentlyActivatedDateField;
          this.handleSingleDateUpdate(activeField, latestSelectedDateObj);
          this.cdRef.detectChanges();
        },
        onDayCreate: async (dObj:Date[], dStr:string, fp:flatpickr.Instance, dayElem:DayElement) => {
          onDayCreate(
            dayElem,
            this.ignoreNonWorkingDays,
            await this.datePickerInstance?.isNonWorkingDay(dayElem.dateObj),
            this.isDayDisabled(dayElem, minimalDate),
          );
        },
      },
      this.flatpickrTarget.nativeElement as HTMLElement,
    );
  }

  private enforceManualChangesToDatepicker(enforceDate?:Date) {
    let startDate = parseDate(this.dates.start || '');
    let endDate = parseDate(this.dates.end || '');

    if (startDate && endDate) {
      // If the start date is manually changed to be after the end date,
      // we adjust the end date to be at least the same as the newly entered start date.
      // Same applies if the end date is set manually before the current start date
      if (startDate > endDate && this.isStateOfCurrentActivatedField('start')) {
        endDate = startDate;
        this.dates.end = this.timezoneService.formattedISODate(endDate);
      } else if (endDate < startDate && this.isStateOfCurrentActivatedField('end')) {
        startDate = endDate;
        this.dates.start = this.timezoneService.formattedISODate(startDate);
      }
    }

    const dates = [startDate, endDate];
    setDates(dates, this.datePickerInstance, enforceDate);
  }

  private setDates(newStart:Date, newEnd:Date) {
    this.dates.start = this.timezoneService.formattedISODate(newStart);
    this.dates.end = this.timezoneService.formattedISODate(newEnd);
  }

  private handleSingleDateUpdate(activeField:DateFields, selectedDate:Date) {
    if (activeField === 'duration') {
      return;
    }

    this.replaceDatesWithNewSelection(activeField, selectedDate);

    // Set the selected date on the datepicker
    this.enforceManualChangesToDatepicker(selectedDate);
  }

  private replaceDatesWithNewSelection(activeField:DateFields, selectedDate:Date) {
    /**
     Overwrite flatpickr default behavior by not starting a new date range everytime but preserving either start or end date.
     There are three cases to cover.
     1. Everything before the current start date will become the new start date (independent of the active field)
     2. Everything after the current end date will become the new end date if that is the currently active field.
     If the active field is the start date, the selected date becomes the new start date and the end date is cleared.
     3. Everything in between the current start and end date is dependent on the currently activated field.
     * */

    const parsedStartDate = parseDate(this.dates.start || '') as Date;
    const parsedEndDate = parseDate(this.dates.end || '') as Date;

    if (selectedDate < parsedStartDate) {
      if (activeField === 'start') {
        // Set start, derive end from
        this.applyNewDates([selectedDate]);
      } else {
        // Reset and end date
        this.applyNewDates(['', selectedDate]);
      }
    } else if (selectedDate > parsedEndDate) {
      if (activeField === 'end') {
        this.applyNewDates([parsedStartDate, selectedDate]);
      } else {
        // Reset and end date
        this.applyNewDates([selectedDate]);
      }
    } else if (areDatesEqual(selectedDate, parsedStartDate) || areDatesEqual(selectedDate, parsedEndDate)) {
      this.applyNewDates([selectedDate, selectedDate]);
    } else {
      const newDates = activeField === 'start' ? [selectedDate, parsedEndDate] : [parsedStartDate, selectedDate];
      this.applyNewDates(newDates);
    }
  }

  private applyNewDates([start, end]:DateOption[]) {
    this.dates.start = start ? this.timezoneService.formattedISODate(start) : null;
    this.dates.end = end ? this.timezoneService.formattedISODate(end) : null;

    // Apply the dates to the datepicker
    setDates([start, end], this.datePickerInstance);
  }

  private get initialActivatedField():DateFields {
    switch (this.fieldName) {
      case 'startDate':
        return 'start';
      case 'dueDate':
        return 'end';
      case 'duration':
        return 'duration';
      default:
        return (this.dates.start && !this.dates.end) ? 'end' : 'start';
    }
  }

  private isDayDisabled(dayElement:DayElement, minimalDate?:Date|null):boolean {
    return !!minimalDate && dayElement.dateObj <= minimalDate;
  }

  private debouncedInput(input$:Subject<string>, key:DateKeys):Observable<ActiveDateChange> {
    return input$
      .pipe(
        this.untilDestroyed(),
        // Skip values that are already set as the current model
        filter((value) => value !== this.dates[key]),
        // Avoid that the manual changes are moved to the datepicker too early.
        // The debounce is chosen quite large on purpose to catch the following case:
        //   1. Start date is for example 2022-07-15. The user wants to set the end date to the 19th.
        //   2. So he/she starts entering the finish date 2022-07-1 .
        //   3. This is already a valid date. Since it is before the start date,the start date would be changed automatically to the first without the debounce.
        //   4. The debounce gives the user enough time to type the last number "9" before the changes are converted to the datepicker and the start date would be affected.
        debounceTime(500),
        filter((date) => validDate(date)),
        map((date) => {
          if (date === '') {
            return null;
          }

          return parseDate(date) as Date;
        }),
        map((date) => [key, date]),
      );
  }

  /**
   * When hovering selections in the range datepicker, the range usually
   * stays active no matter where the cursor is.
   *
   * We want to hide any hovered selection preview when we leave the datepicker.
   * @param calendarContainer
   * @private
   */
  private ensureHoveredSelection(calendarContainer:HTMLDivElement) {
    fromEvent(calendarContainer, 'mouseenter')
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(() => calendarContainer.classList.remove('flatpickr-container-suppress-hover'));

    fromEvent(calendarContainer, 'mouseleave')
      .pipe(
        this.untilDestroyed(),
        filter(() => !(!!this.dates.start && !!this.dates.end)),
      )
      .subscribe(() => calendarContainer.classList.add('flatpickr-container-suppress-hover'));
  }

  writeValue(newValue:string[]|null):void {
    const value = (newValue || []).map((d) => this.timezoneService.formattedISODate(d));
    if (value[0] === this.dates.start && value[1] === this.dates.end) {
      return;
    }
    this.value = value;
    this.dates.start = this.value[0];
    this.dates.end = this.value[1];
  }

  onChange = (_:string[]):void => {};

  onTouched = ():void => {};

  registerOnChange(fn:(_:string[]) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:() => void):void {
    this.onTouched = fn;
  }
}
