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

type DateKeys = 'date'|'start'|'end';

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

  text = {
    save: this.I18n.t('js.button_save'),
    cancel: this.I18n.t('js.button_cancel'),
    clear: this.I18n.t('js.work_packages.button_clear'),
    manualScheduling: this.I18n.t('js.scheduling.manual'),
    automaticScheduling: this.I18n.t('js.scheduling.automatic'),
    date: this.I18n.t('js.work_packages.properties.date'),
    startDate: this.I18n.t('js.work_packages.properties.startDate'),
    endDate: this.I18n.t('js.work_packages.properties.dueDate'),
    placeholder: this.I18n.t('js.placeholders.default')
  };

  private datePickerInstance:DatePicker;

  public singleDate = false;

  public scheduleManually = false;

  public dates:{ [key in DateKeys]:string } = {
    date: '',
    start: '',
    end: ''
  };

  private changeset:ResourceChangeset;

  constructor(readonly injector:Injector,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef) {
    super(locals, cdRef, elementRef);
    this.changeset = locals.changeset;

    this.singleDate = this.changeset.isWritable('date');
    this.scheduleManually = this.changeset.value('scheduleManually');

    if (this.singleDate) {
      this.dates.date = this.changeset.value('date');
    } else {
      this.dates.start = this.changeset.value('startDate');
      this.dates.end = this.changeset.value('dueDate');
    }
  }

  ngAfterViewInit():void {
    this.initializeDatepicker();
  }

  changeSchedulingMode() {
    this.scheduleManually = !this.scheduleManually;
    this.cdRef.detectChanges();
  }

  save():void {
    if (this.singleDate) {
      this.changeset.setValue('date', this.dates.date);
    } else {
      this.changeset.setValue('startDate', this.dates.start);
      this.changeset.setValue('dueDate', this.dates.end);
    }

    this.changeset.setValue('scheduleManually', !this.changeset.value('scheduleManually'));
    this.closeMe();
  }

  cancel():void {
    this.closeMe();
  }

  clear():void {
    this.datePickerInstance.clear();
  }

  formattedDate(key:DateKeys) {
    const val = this.dates[key];

    if (!val) {
      return this.text.placeholder;
    }

    if (this.validDate(val)) {
      let parsed = this.timezoneService.parseDate(val);
      return this.timezoneService.formattedISODate(parsed);
    } else {
      return val;
    }
  }

  updateDate(key:DateKeys, val:string) {
    this.dates[key] = val;
    if (this.validDate(val) && this.datePickerInstance) {
      this.setDatesToDatepicker();
    }
  }

  schedulingButtonText():string {
    return this.locals.scheduleManually ? this.text.automaticScheduling : this.text.manualScheduling;
  }

  schedulingButtonIcon():string {
    return 'button--icon ' + (this.locals.scheduleManually ? 'icon-arrow-left-right' : 'icon-pin');
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
        mode: this.singleDate ? 'single' : 'range',
        inline: true,
        onChange: (dates:Date[]) => {
          if (this.singleDate && dates.length === 1) {
            this.dates.date = this.timezoneService.formattedISODate(dates[0]);
          }

          if (!this.singleDate && dates.length >= 1) {
            this.dates.start = this.timezoneService.formattedISODate(dates[0]);
            this.dates.end = '-';
          }

          if (dates.length >= 2) {
            this.dates.end = dates[1] ? this.timezoneService.formattedISODate(dates[1]) : '-';
          }

          this.cdRef.detectChanges();
        }
      }
    );
  }

  private setDatesToDatepicker() {
    if (this.singleDate) {
      let date = this.parseDate(this.dates.date);
      this.datePickerInstance.setDates(date);
    } else {
      let dates = [this.parseDate(this.dates.start), this.parseDate(this.dates.end)];
      this.datePickerInstance.setDates(dates);
    }
  }

  private validDate(date:Date|string) {
    if (date instanceof Date) {
      return true;
    } else {
      return !!new Date(date).valueOf();
    }
  }

  private parseDate(date:Date|string):Date {
    if (date instanceof Date) {
      return date;
    } else {
      return new Date(date);
    }
  }
}
