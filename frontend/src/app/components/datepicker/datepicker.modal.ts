// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  Inject,
  Injector,
  ViewEncapsulation
} from "@angular/core";
import {OpModalComponent} from "core-components/op-modals/op-modal.component";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import {TimezoneService} from "core-components/datetime/timezone.service";
import {DatePicker} from "core-app/modules/common/op-date-picker/datepicker";
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {ResourceChangeset} from "core-app/modules/fields/changeset/resource-changeset";
import {DatepickerHelper} from "core-components/datepicker/datepicker.helper";

export type DateKeys = 'date'|'start'|'end';

@Component({
  templateUrl: './datepicker.modal.html',
  styleUrls: ['./datepicker.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None
})
export class DatePickerModal extends OpModalComponent implements AfterViewInit {
  @InjectField() I18n:I18nService;
  @InjectField() timezoneService:TimezoneService;
  @InjectField() halEditing:HalResourceEditingService;
  @InjectField() datepickerHelper:DatepickerHelper;

  text = {
    save: this.I18n.t('js.button_save'),
    cancel: this.I18n.t('js.button_cancel'),
    clear: this.I18n.t('js.modals.button_clear_all'),
    manualScheduling: this.I18n.t('js.scheduling.manual'),
    date: this.I18n.t('js.work_packages.properties.date'),
    startDate: this.I18n.t('js.work_packages.properties.startDate'),
    endDate: this.I18n.t('js.work_packages.properties.dueDate'),
    placeholder: this.I18n.t('js.placeholders.default')
  };
  public onDataUpdated = new EventEmitter<string>();

  public singleDate = false;

  public scheduleManually = false;

  public htmlId:string = '';

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
              readonly elementRef:ElementRef) {
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
      this.datepickerHelper.setCurrentActivatedField(this.locals.fieldName === 'dueDate' ? 'end' : 'start');
    }
  }

  ngAfterViewInit():void {
    this.initializeDatepicker();
    this.datepickerHelper.setDatepickerRestrictions(this.dates, this.datePickerInstance);
    this.datepickerHelper.setRangeClasses(this.dates, this.datePickerInstance);

    this.onDataChange();
  }

  changeSchedulingMode() {
    this.scheduleManually = !this.scheduleManually;
    this.cdRef.detectChanges();
  }

  save():void {
    if (this.singleDate) {
      this.changeset.setValue('date', this.datepickerHelper.mappedDate(this.dates.date));
    } else {
      this.changeset.setValue('startDate', this.datepickerHelper.mappedDate(this.dates.start));
      this.changeset.setValue('dueDate', this.datepickerHelper.mappedDate(this.dates.end));
    }

    this.changeset.setValue('scheduleManually', this.scheduleManually);
    this.closeMe();
  }

  cancel():void {
    this.closeMe();
  }

  clear():void {
    this.dates = {
      date: '',
      start: '',
      end: ''
    };

    this.datePickerInstance.clear();
  }

  updateDate(key:DateKeys, val:string) {
    this.dates[key] = val;
    if (this.datepickerHelper.validDate(val) && this.datePickerInstance) {
      this.setDatesToDatepicker();
    }
  }

  reposition(element:JQuery<HTMLElement>, target:JQuery<HTMLElement>) {
    element.position({
      my: 'left top',
      at: 'left bottom',
      of: target,
      collision: 'flipfit'
    });
  }

  private initializeDatepicker() {
    this.datePickerInstance = new DatePicker(
      '#flatpickr-input',
      this.singleDate ? this.dates.date : [this.dates.start, this.dates.end],
      {
        mode: this.singleDate ? 'single' : 'multiple',
        inline: true,
        onChange: (dates:Date[]) => {
          this.onDatePickerChange(dates);

          this.onDataChange();
        },
        onMonthChange: () => { this.datepickerHelper.setRangeClasses(this.dates, this.datePickerInstance); },
        onYearChange: () => { this.datepickerHelper.setRangeClasses(this.dates, this.datePickerInstance); },
      }
    );
  }

  private setDatesToDatepicker() {
    if (this.singleDate) {
      let date = this.datepickerHelper.parseDate(this.dates.date);
      this.datePickerInstance.setDates(date);
    } else {
      let dates = [this.datepickerHelper.parseDate(this.dates.start), this.datepickerHelper.parseDate(this.dates.end)];
      this.datePickerInstance.setDates(dates);
    }
  }

  private onDatePickerChange(dates:Date[]) {
    switch (dates.length) {
      case 0: {
        break;
      }
      case 1: {
        if (this.singleDate) {
          this.dates.date = this.timezoneService.formattedISODate(dates[0]);
        } else {
          if (this.dates.start && this.dates.end) {
            // In case we remove a value by clicking on the selected date within the datepicker
            this.dates[this.datepickerHelper.currentlyActivatedDateField] = '';
          } else {
            this.dates[this.datepickerHelper.currentlyActivatedDateField] = this.timezoneService.formattedISODate(dates[0]);
            this.datepickerHelper.toggleCurrentActivatedField(this.dates, this.datePickerInstance);
          }
        }

        break;
      }
      case 2: {
        if ((!this.dates.end && this.datepickerHelper.isStateOfCurrentActivatedField('start')) ||
            (!this.dates.start && this.datepickerHelper.isStateOfCurrentActivatedField('end'))) {
          // If we change a start date when no end date is set, we keep only the newly clicked value and not both
          this.datePickerInstance.setDates([dates[1]]);
          this.onDatePickerChange([dates[1]]);
        } else {
          // Sort dates so that the start date is always first
          if (dates[0] > dates[1]) {
            dates.sort(function(a:Date, b:Date) {
              return a.getTime() - b.getTime();
            });
            this.datePickerInstance.setDates([dates[0], dates[1]]);
          }

          let index = this.datepickerHelper.isStateOfCurrentActivatedField('start') ? 0 : 1;
          this.dates[this.datepickerHelper.currentlyActivatedDateField] = this.timezoneService.formattedISODate(dates[index]);

          this.datepickerHelper.toggleCurrentActivatedField(this.dates, this.datePickerInstance);
          this.datepickerHelper.setRangeClasses(this.dates, this.datePickerInstance);
        }

        break;
      }
      default: {
        // Reset the date picker with the two new values
        if (this.datepickerHelper.isStateOfCurrentActivatedField('start')) {
          this.datePickerInstance.setDates([dates[2], dates[1]]);
          this.onDatePickerChange([dates[2], dates[1]]);
        } else {
          this.datePickerInstance.setDates([dates[0], dates[2]]);
          this.onDatePickerChange([dates[0], dates[2]]);
        }

        break;
      }
    }

    this.cdRef.detectChanges();
  }

  private onDataChange() {
    let date = this.dates.date || '';
    let start = this.dates.start || '';
    let end = this.dates.end || '';

    let output = this.singleDate ? date : start + ' - ' + end;
    this.onDataUpdated.emit(output);
  }
}
