//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  Inject,
  Injector, ViewChild,
  ViewEncapsulation
} from "@angular/core";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { OpModalComponent } from "core-app/modules/modal/modal.component";
import { OpModalLocalsMap } from "core-app/modules/modal/modal.types";
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import { TimezoneService } from "core-components/datetime/timezone.service";
import { DatePicker } from "core-app/modules/common/op-date-picker/datepicker";
import { HalResourceEditingService } from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import { ResourceChangeset } from "core-app/modules/fields/changeset/resource-changeset";
import { DatePickerModalHelper } from "core-components/datepicker/datepicker.modal.helper";
import { BrowserDetector } from "core-app/modules/common/browser/browser-detector.service";
import { ConfigurationService } from "core-app/modules/common/config/configuration.service";

export type DateKeys = 'date'|'start'|'end';

@Component({
  templateUrl: './datepicker.modal.html',
  styleUrls: ['./datepicker.modal.sass', './datepicker_mobile.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None
})
export class DatePickerModal extends OpModalComponent implements AfterViewInit {
  @InjectField() I18n!:I18nService;
  @InjectField() timezoneService:TimezoneService;
  @InjectField() halEditing:HalResourceEditingService;
  @InjectField() datepickerHelper:DatePickerModalHelper;
  @InjectField() browserDetector:BrowserDetector;

  @ViewChild('modalContainer') modalContainer:ElementRef<HTMLElement>;

  text = {
    save: this.I18n.t('js.button_save'),
    cancel: this.I18n.t('js.button_cancel'),
    clear: this.I18n.t('js.work_packages.button_clear'),
    manualScheduling: this.I18n.t('js.scheduling.manual'),
    date: this.I18n.t('js.work_packages.properties.date'),
    startDate: this.I18n.t('js.work_packages.properties.startDate'),
    endDate: this.I18n.t('js.work_packages.properties.dueDate'),
    placeholder: this.I18n.t('js.placeholders.default'),
    today: this.I18n.t('js.label_today'),
    isParent: this.I18n.t('js.work_packages.scheduling.is_parent'),
    isSwitchedFromManualToAutomatic: this.I18n.t('js.work_packages.scheduling.is_switched_from_manual_to_automatic')
  };
  public onDataUpdated = new EventEmitter<string>();

  public singleDate = false;

  public scheduleManually = false;

  public htmlId = '';

  public dates:{ [key in DateKeys]:string } = {
    date: '',
    start: '',
    end: ''
  };

  private changeset:ResourceChangeset;

  private datePickerInstance:DatePicker;

  constructor(readonly injector:Injector,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef,
              readonly configurationService:ConfigurationService) {
    super(locals, cdRef, elementRef);
    this.changeset = locals.changeset;
    this.htmlId = `wp-datepicker-${locals.fieldName}`;

    this.singleDate = this.changeset.isWritable('date');
    this.scheduleManually = this.changeset.value('scheduleManually');

    if (this.singleDate) {
      this.dates.date = this.changeset.value('date');
      this.datepickerHelper.setCurrentActivatedField('date');
    } else {
      this.dates.start = this.changeset.value('startDate');
      this.dates.end = this.changeset.value('dueDate');
      this.datepickerHelper.setCurrentActivatedField(this.initialActivatedField());
    }
  }

  ngAfterViewInit():void {
    if (this.isSchedulable) {
      this.showDateSelection();
    }

    this.onDataChange();
  }

  changeSchedulingMode() {
    this.scheduleManually = !this.scheduleManually;
    this.cdRef.detectChanges();

    if (this.scheduleManually) {
      this.showDateSelection();
    } else if (this.isParent) {
      this.removeDateSelection();
    }
  }

  save($event:Event):void {
    $event.preventDefault();
    if (!this.isSavable) {
      return;
    }

    // Apply the changed scheduling mode if any
    this.changeset.setValue('scheduleManually', this.scheduleManually);

    // Apply the dates if they could be changed
    if (this.isSchedulable) {
      if (this.singleDate) {
        this.changeset.setValue('date', this.datepickerHelper.mappedDate(this.dates.date));
      } else {
        this.changeset.setValue('startDate', this.datepickerHelper.mappedDate(this.dates.start));
        this.changeset.setValue('dueDate', this.datepickerHelper.mappedDate(this.dates.end));
      }
    }

    this.closeMe();
  }

  cancel():void {
    this.closeMe();
  }

  clear(key:DateKeys):void {
    this.dates[key] = '';
    this.enforceManualChangesToDatepicker();
  }

  updateDate(key:DateKeys, val:string) {
    // Expected minimal format YYYY-M-D => 8 characters OR empty
    if (val.length >= 8 || val.length === 0) {
      this.dates[key] = val;
      if (this.datepickerHelper.validDate(val) && this.datePickerInstance) {
        this.enforceManualChangesToDatepicker(false);
      }
    }
  }

  setToday(key:DateKeys) {
    const today = this.datepickerHelper.parseDate(new Date());
    this.dates[key] = this.timezoneService.formattedISODate(today);

    (today instanceof Date) ? this.enforceManualChangesToDatepicker(true, today) : this.enforceManualChangesToDatepicker();
  }

  reposition(element:JQuery<HTMLElement>, target:JQuery<HTMLElement>) {
    element.position({
      my: 'left top',
      at: 'left bottom',
      of: target,
      collision: 'flipfit'
    });
  }

  setCurrentActivatedField(key:DateKeys) {
    this.datepickerHelper.setCurrentActivatedField(key);
    this.datepickerHelper.setDatepickerRestrictions(this.dates, this.datePickerInstance);
    this.datepickerHelper.setRangeClasses(this.dates);
  }

  showTodayLink(key:DateKeys):boolean {
    if (!this.isSchedulable) {
      return false;
    }

    if (key === 'start') {
      return this.datepickerHelper.parseDate(new Date()) <= this.datepickerHelper.parseDate(this.dates.end);
    } else {
      return this.datepickerHelper.parseDate(new Date()) >= this.datepickerHelper.parseDate(this.dates.start);
    }
  }

  /**
   * Returns whether the user can alter the dates of the work package.
   * The work package is always schedulable if the work package scheduled manually.
   * But it might also be altered in automatic scheduling mode if it does not have children and if there was
   * no switch from manual to automatic scheduling.
   * The later is necessary as we cannot correctly calculate the resulting dates in the frontend.
   */
  get isSchedulable():boolean {
    return this.scheduleManually || (!this.isParent && !this.isSwitchedFromManualToAutomatic);
  }

  get isSavable():boolean {
    return this.isSchedulable || this.isSwitchedFromManualToAutomatic;
  }

  /**
   * Determines whether the work package is a parent. It does so
   * by checking the children links.
   */
  get isParent():boolean {
    return this.changeset.projectedResource.$links.children && this.changeset.projectedResource.$links.children.length > 0;
  }

  get isSwitchedFromManualToAutomatic():boolean {
    return !this.scheduleManually && this.changeset.value('scheduleManually');
  }

  private showDateSelection() {
    this.initializeDatepicker();
    this.datepickerHelper.setDatepickerRestrictions(this.dates, this.datePickerInstance);
    this.datepickerHelper.setRangeClasses(this.dates);
  }

  private removeDateSelection() {
    this.datePickerInstance.destroy();
  }

  private initializeDatepicker() {
    this.datePickerInstance?.destroy();
    this.datePickerInstance = new DatePicker(
      '#flatpickr-input',
      this.singleDate ? this.dates.date : [this.dates.start, this.dates.end],
      {
        mode: this.singleDate ? 'single' : 'multiple',
        showMonths: this.browserDetector.isMobile ? 1 : 2,
        inline: true,
        onChange: (dates:Date[]) => {
          this.handleDatePickerChange(dates);

          this.onDataChange();
        },
        onMonthChange: () => {
          this.datepickerHelper.setRangeClasses(this.dates);
        },
        onYearChange: () => {
          this.datepickerHelper.setRangeClasses(this.dates);
        },
      },
      undefined,
      this.configurationService
    );
  }

  private enforceManualChangesToDatepicker(toggleField = true, enforceDate?:Date) {
    if (this.singleDate) {
      const date = this.datepickerHelper.parseDate(this.dates.date);
      this.datepickerHelper.setDates(date, this.datePickerInstance, enforceDate);
    } else {
      const dates = [this.datepickerHelper.parseDate(this.dates.start), this.datepickerHelper.parseDate(this.dates.end)];
      this.datepickerHelper.setDates(dates, this.datePickerInstance, enforceDate);

      this.setRangeClassesAndToggleActiveField(toggleField);
    }
  }

  private handleDatePickerChange(dates:Date[]) {
    switch (dates.length) {
    case 0: {
      // In case we removed the only value by clicking on a already selected date within the datepicker:
      if (this.dates.start || this.dates.end) {
        this.setDateAndToggleActiveField(this.dates.start || this.dates.end);
      }

      break;
    }
    case 1: {
      if (this.singleDate) {
        this.dates.date = this.timezoneService.formattedISODate(dates[0]);
      } else {
        // In case we removed a value by clicking on a already selected date within the datepicker:
        if (this.dates.start && this.dates.end) {
          // Both dates are the same, so it is correct to only highlight one date
          if (this.dates.start === this.dates.end) {
            return;
          }

          // I wanted to set the new start date to the preselected endDate OR
          // I wanted to set the new end date to the preselected startDate
          if ((this.datepickerHelper.isStateOfCurrentActivatedField('start') && this.datepickerHelper.areDatesEqual(this.dates.start, dates[0])) ||
                (this.datepickerHelper.isStateOfCurrentActivatedField('end') && this.datepickerHelper.areDatesEqual(this.dates.end, dates[0]))) {

            const otherDateIndex:DateKeys = this.datepickerHelper.isStateOfCurrentActivatedField('start') ? 'end' : 'start';
            this.setDateAndToggleActiveField(this.dates[otherDateIndex]);
          } else {
            // I clicked on the already set start or end date (and thus removed it):
            // We restore both values
            this.enforceManualChangesToDatepicker(true);
          }
        } else {
          // It is the first value we set (either start or end date)
          this.setDateAndToggleActiveField(this.timezoneService.formattedISODate(dates[0]), false);
        }
      }

      break;
    }
    case 2: {
      if ((!this.dates.end && this.datepickerHelper.isStateOfCurrentActivatedField('start')) ||
            (!this.dates.start && this.datepickerHelper.isStateOfCurrentActivatedField('end'))) {
        // If we change a start date when no end date is set, we keep only the newly clicked value and not both
        this.overwriteDatePickerWithNewDates([dates[1]]);
      } else {
        // Sort dates so that the start date is always first
        if (dates[0] > dates[1]) {
          dates = this.datepickerHelper.sortDates(dates);
          this.datepickerHelper.setDates(dates, this.datePickerInstance);
        }

        const index = this.datepickerHelper.isStateOfCurrentActivatedField('start') ? 0 : 1;
        this.dates[this.datepickerHelper.currentlyActivatedDateField] = this.timezoneService.formattedISODate(dates[index]);

        this.setRangeClassesAndToggleActiveField();
      }

      break;
    }
    default: {
      // Reset the date picker with the two new values
      if (this.datepickerHelper.isStateOfCurrentActivatedField('start')) {
        this.overwriteDatePickerWithNewDates([dates[2], dates[1]]);
      } else {
        this.overwriteDatePickerWithNewDates([dates[0], dates[2]]);
      }

      break;
    }
    }

    this.cdRef.detectChanges();
  }

  private overwriteDatePickerWithNewDates(dates:Date[]) {
    this.datepickerHelper.setDates(dates, this.datePickerInstance);
    this.handleDatePickerChange(dates);
  }

  private setDateAndToggleActiveField(newDate:string, forceDatePickerUpdate = true) {
    this.dates[this.datepickerHelper.currentlyActivatedDateField] = newDate;
    if (forceDatePickerUpdate) {
      this.datepickerHelper.setDates([this.datepickerHelper.parseDate(newDate)], this.datePickerInstance);
    }
    this.datepickerHelper.toggleCurrentActivatedField(this.dates, this.datePickerInstance);
  }

  private setRangeClassesAndToggleActiveField(toggleField = true) {
    if (toggleField) {
      this.datepickerHelper.toggleCurrentActivatedField(this.dates, this.datePickerInstance);
    }
    this.datepickerHelper.setRangeClasses(this.dates);
  }

  private onDataChange() {
    const date = this.dates.date || '';
    const start = this.dates.start || '';
    const end = this.dates.end || '';

    const output = this.singleDate ? date : start + ' - ' + end;
    this.onDataUpdated.emit(output);
  }

  private initialActivatedField():DateKeys {
    return this.locals.fieldName === 'dueDate' || (this.dates.start && !this.dates.end) ? 'end' : 'start';
  }

}
