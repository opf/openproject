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
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  HostBinding,
  Injector,
  Input,
  OnChanges,
  Output,
  SimpleChanges,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { onDayCreate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DatePicker } from '../datepicker';
import flatpickr from 'flatpickr';
import { DayElement } from 'flatpickr/dist/types/instance';
import { DeviceService } from 'core-app/core/browser/device.service';

@Component({
  selector: 'op-datepicker-sheet',
  templateUrl: './date-picker-sheet.component.html',
  styleUrls: [
    '../styles/datepicker.modal.sass',
    './date-picker-sheet.component.sass',
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class OpDatePickerSheetComponent implements AfterViewInit, OnChanges {
  @HostBinding('class.op-datepicker-sheet') className = true;

  @Input() dates:string[];

  @Input() mode:'range'|'single';

  @Input() ignoreNonWorkingDays = true;

  @Input() isDisabled = (_dayElem:DayElement) => false;

  @Output() datesSelected = new EventEmitter<string[]>();

  @ViewChild('flatpickrTarget') flatpickrTarget:ElementRef<HTMLElement>;

  datePickerInstance:DatePicker;

  constructor(
    readonly I18n:I18nService,
    readonly timezoneService:TimezoneService,
    readonly injector:Injector,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly deviceService:DeviceService,
  ) {
  }

  ngAfterViewInit():void {
    this.initializeDatepicker();
  }

  ngOnChanges(changes:SimpleChanges) {
    if (changes.dates && !changes.dates.isFirstChange()) {
      this.datePickerInstance.setDates(changes.dates.currentValue as string[]);
    }

    if (changes.mode && !changes.mode.isFirstChange()) {
      this.initializeDatepicker();
    }
  }

  private initializeDatepicker() {
    this.datePickerInstance?.destroy();
    this.datePickerInstance = new DatePicker(
      this.injector,
      '#flatpickr-input',
      this.dates,
      {
        mode: this.mode,
        showMonths: (this.deviceService.isMobile || this.mode === 'single') ? 1 : 2,
        inline: true,
        onChange: (dates:Date[]) => {
          const formatted = dates.map((el:Date) => this.timezoneService.formattedISODate(el));
          this.datesSelected.emit(formatted);
        },
        // eslint-disable-next-line @typescript-eslint/no-misused-promises
        onDayCreate: async (dObj:Date[], dStr:string, fp:flatpickr.Instance, dayElem:DayElement) => {
          onDayCreate(
            dayElem,
            this.ignoreNonWorkingDays,
            await this.datePickerInstance?.isNonWorkingDay(dayElem.dateObj),
            this.isDisabled(dayElem),
          );
        },
      },
      this.flatpickrTarget.nativeElement,
    );
  }
}
