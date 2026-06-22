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

import { omitBy } from 'lodash-es';
import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Injector, Input, ViewChild, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DayElement } from 'flatpickr/dist/types/instance';
import flatpickr from 'flatpickr';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { onDayCreate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { DeviceService } from 'core-app/core/browser/device.service';
import { DatePicker } from '../datepicker';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { fromEvent } from 'rxjs';
import { filter } from 'rxjs/operators';
import _ from 'lodash';

export type DateMode = 'single'|'range';

@Component({
  selector: 'op-wp-date-picker-instance',
  template: `
    <input
      id="flatpickr-input"
      #flatpickrTarget
      hidden>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class OpWpDatePickerInstanceComponent extends UntilDestroyedMixin implements AfterViewInit {
  readonly injector = inject(Injector);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly apiV3Service = inject(ApiV3Service);
  readonly I18n = inject(I18nService);
  readonly timezoneService = inject(TimezoneService);
  readonly deviceService = inject(DeviceService);
  readonly pathHelper = inject(PathHelperService);
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  @Input() public ignoreNonWorkingDays:boolean;
  @Input() public scheduleManually:boolean;

  @Input() public startDate:string|null;
  @Input() public dueDate:string|null;

  @Input() public isSchedulable = true;
  @Input() public dateMode:DateMode;
  @Input() public minDate:string|null;

  @Input() startDateFieldId:string;
  @Input() dueDateFieldId:string;
  @Input() durationFieldId:string;

  @Input() isMilestone = false;

  @ViewChild('flatpickrTarget') flatpickrTarget:ElementRef<HTMLInputElement>;

  private datePickerInstance:DatePicker;
  private startDateValue:Date|null;
  private dueDateValue:Date|null;
  private minimalSchedulingDate:Date|null;
  private onFlatpickrSetValuesBound = this.onFlatpickrSetValues.bind(this);

  constructor() {
    super();
    populateInputsFromDataset(this);
    this.startDateValue = this.toDate(this.startDate);
    this.dueDateValue = this.toDate(this.dueDate);
    this.computeMinimalSchedulingDate();
  }

  ngAfterViewInit():void {
    this.initializeDatepicker();

    document.addEventListener('date-picker:flatpickr-set-values', this.onFlatpickrSetValuesBound);
  }

  // eslint-disable-next-line @angular-eslint/use-lifecycle-interface
  ngOnDestroy():void {
    super.ngOnDestroy();

    document.removeEventListener('date-picker:flatpickr-set-values', this.onFlatpickrSetValuesBound);
  }

  onFlatpickrSetValues(
    event:CustomEvent<{
      dates:Date[];
      ignoreNonWorkingDays:boolean;
      mode:DateMode;
    }>,
  ) {
    const details = event.detail;

    // flatpickr jumps the calendar date to the last date, which is annoying
    // when the start date is changed. Find which date has changed and jump to
    // that date if it's not visible.
    const dateToJumpTo = this.findDateToJumpTo(details.dates);
    [this.startDateValue, this.dueDateValue] = details.dates;
    this.computeMinimalSchedulingDate();
    this.setDatePickerDates(details.dates, dateToJumpTo);

    this.datePickerInstance.setOption('mode', details.mode);

    if (this.ignoreNonWorkingDays !== details.ignoreNonWorkingDays) {
      this.ignoreNonWorkingDays = details.ignoreNonWorkingDays;
      this.datePickerInstance.datepickerInstance.redraw();
    }

    // If both dates are set, we want to see the selection state
    if (details.dates.length === 2) {
      this.allowHoverFor(this.datePickerInstance.datepickerInstance.calendarContainer);
    }
  }

  private computeMinimalSchedulingDate() {
    if (this.dateMode === 'single') {
      this.minimalSchedulingDate = null;
    } else {
      this.minimalSchedulingDate = this.startDateValue && this.timezoneService.utcDateToLocalDate(this.startDateValue);
    }
  }

  private findDateToJumpTo(dates:Date[]):Date|null {
    const [start, end] = dates;
    if (start && start?.getTime() !== this.startDateValue?.getTime()) {
      return start;
    }
    if (end?.getTime() !== this.dueDateValue?.getTime()) {
      // if end date changed to null, we jump to the start date, even if it did not change
      return end || start || null;
    }
    return null;
  }

  private isDifferentFromDatePickerSelectedDates(isoDates:string[]):boolean {
    const datePickerSelectedDates = this.datePickerInstance.datepickerInstance.selectedDates;
    const isoDatePickerSelectedDates = datePickerSelectedDates.map((date) => this.timezoneService.formattedISODate(date));
    return !_.isEqual(isoDates, isoDatePickerSelectedDates);
  }

  // set dates on flatpickr, trying to avoid jumping to a different month when possible
  private setDatePickerDates(dates:Date[], jumpToDate:Date|null) {
    const monthBefore = this.datePickerInstance.datepickerInstance.currentMonth;
    const yearBefore = this.datePickerInstance.datepickerInstance.currentYear;

    // only set dates if they changed to avoid jumping
    const isoDates = this.timezoneService.utcDatesToISODateStrings(dates);
    if (this.isDifferentFromDatePickerSelectedDates(isoDates)) {
      this.datePickerInstance.setDates(isoDates);
    }

    // jump to the date that has been changed if there is one
    if (jumpToDate) {
      this.datePickerInstance.datepickerInstance.jumpToDate(jumpToDate, false);
    }

    // if we only show one month, we don't need to jump to a different month
    if (this.datePickerInstance.datepickerInstance.config.showMonths === 1) {
      return;
    }

    const monthNow = this.datePickerInstance.datepickerInstance.currentMonth;
    const yearNow = this.datePickerInstance.datepickerInstance.currentYear;

    if (dates.length === 0 || jumpToDate === null) {
      // if no dates are selected, jump to the month and year previously displayed
      const dateBefore = new Date(Date.UTC(yearBefore, monthBefore, 2));
      this.datePickerInstance.datepickerInstance.jumpToDate(dateBefore, false);
    } else if ((monthNow === monthBefore + 1 && yearNow === yearBefore)
              || (monthNow === 0 && monthBefore === 11 && yearNow === yearBefore + 1)) {
      // if the month on the left now is the one that was on the right before, jump one month back
      this.datePickerInstance.datepickerInstance.changeMonth(-1);
    }
  }

  private toDate(date:string|null):Date|null {
    return date ? new Date(date) : null;
  }

  private currentDates():string[] {
    const compactedDates = [this.startDateValue, this.dueDateValue].filter((x):x is NonNullable<typeof x> => Boolean(x));
    return this.timezoneService.utcDatesToISODateStrings(compactedDates);
  }

  private initializeDatepicker() {
    this.datePickerInstance?.destroy();

    this.datePickerInstance = new DatePicker(
      this.injector,
      '#flatpickr-input',
      this.currentDates(),
      this.datePickerOptions(),
      this.flatpickrTarget.nativeElement,
    );
  }

  private datePickerOptions() {
    const options = {
      mode: this.dateMode,
      showMonths: this.deviceService.isMobile ? 1 : 2,
      inline: true,
      onReady: (_date, _datestr, instance) => {
        instance.calendarContainer.classList.add('op-datepicker-modal--flatpickr-instance');

        this.ensureHoveredSelection(instance.calendarContainer);
      },
      onChange: this.onFlatpickrChange.bind(this),
      // eslint-disable-next-line @typescript-eslint/no-misused-promises
      onDayCreate: async (dObj:Date[], dStr:string, fp:flatpickr.Instance, dayElem:DayElement) => {
        onDayCreate(
          dayElem,
          this.ignoreNonWorkingDays,
          await this.datePickerInstance?.isNonWorkingDay(dayElem.dateObj),
          this.isDayDisabled(dayElem),
        );
      },
      minDate: this.minDate,
    } as flatpickr.Options.Options;

    return omitBy(options, (v) => v == null);
  }

  private onFlatpickrChange(dates:Date[], _datestr:string, _instance:flatpickr.Instance) {
    // convert dates to UTC to be able to compare them correctly
    const utcDates = dates.map((date) => new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate())));
    document.dispatchEvent(
      new CustomEvent('date-picker:flatpickr-dates-changed', {
        detail: { dates: utcDates },
      }),
    );
  }

  private isDayDisabled(dayElement:DayElement):boolean {
    return !this.isSchedulable
      || (!this.scheduleManually
        && !!this.minimalSchedulingDate
        && dayElement.dateObj < this.minimalSchedulingDate);
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
      .subscribe(() => this.allowHoverFor(calendarContainer));

    fromEvent(calendarContainer, 'mouseleave')
      .pipe(
        this.untilDestroyed(),
        filter(() => !(!!this.startDateValue && !!this.dueDateValue)),
      )
      .subscribe(() => this.suppressHoverFor(calendarContainer));
  }

  private suppressHoverFor(el:HTMLElement) {
    el.classList.add('flatpickr-container-suppress-hover');
  }

  private allowHoverFor(el:HTMLElement) {
    el.classList.remove('flatpickr-container-suppress-hover');
  }
}
