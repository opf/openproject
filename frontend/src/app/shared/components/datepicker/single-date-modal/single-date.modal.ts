// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
  Inject,
  Injector,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { DatePicker } from 'core-app/shared/components/op-date-picker/datepicker';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { BrowserDetector } from 'core-app/core/browser/browser-detector.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DayElement } from 'flatpickr/dist/types/instance';
import flatpickr from 'flatpickr';
import { DatepickerModalService } from 'core-app/shared/components/datepicker/datepicker.modal.service';
import {
  debounce,
  switchMap,
  take,
} from 'rxjs/operators';
import { activeFieldContainerClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import {
  Subject,
  timer,
} from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { FormResource } from 'core-app/features/hal/resources/form-resource';

@Component({
  templateUrl: './single-date.modal.html',
  styleUrls: ['../datepicker.modal.sass', '../datepicker_mobile.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  providers: [
    DatepickerModalService,
  ],
})
export class SingleDateModalComponent extends OpModalComponent implements AfterViewInit {
  @InjectField() I18n!:I18nService;

  @InjectField() timezoneService:TimezoneService;

  @InjectField() halEditing:HalResourceEditingService;

  @InjectField() datepickerService:DatepickerModalService;

  @InjectField() browserDetector:BrowserDetector;

  @ViewChild('modalContainer') modalContainer:ElementRef<HTMLElement>;

  text = {
    save: this.I18n.t('js.button_save'),
    cancel: this.I18n.t('js.button_cancel'),
    manualScheduling: this.I18n.t('js.scheduling.manual'),
    date: this.I18n.t('js.work_packages.properties.date'),
    includeNonWorkingDays: this.I18n.t('js.work_packages.datepicker_modal.include_non_working_days'),
    placeholder: this.I18n.t('js.placeholders.default'),
    today: this.I18n.t('js.label_today'),
  };

  onDataUpdated = new EventEmitter<string>();

  scheduleManually = false;

  includeNonWorkingDays = false;

  htmlId = '';

  date:string|null = null;

  dateChangedManually$ = new Subject<void>();

  private debounceDelay = 0; // will change after initial render

  private changeset:ResourceChangeset;

  private datePickerInstance:DatePicker;

  private dateUpdates$ = new Subject<string>();

  private dateUpdateRequests$ = this
    .dateUpdates$
    .pipe(
      this.untilDestroyed(),
      switchMap((date:string) => this
        .apiV3Service
        .work_packages
        .id(this.changeset.id)
        .form
        .forPayload({
          date,
          lockVersion: this.changeset.value<string>('lockVersion'),
          ignoreNonWorkingDays: this.includeNonWorkingDays,
        })),
    )
    .subscribe((form) => this.updateDatesFromForm(form));

  constructor(
    readonly injector:Injector,
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly configurationService:ConfigurationService,
    readonly apiV3Service:ApiV3Service,
  ) {
    super(locals, cdRef, elementRef);
    this.changeset = locals.changeset as ResourceChangeset;
    this.htmlId = `wp-datepicker-${locals.fieldName as string}`;

    this.scheduleManually = !!this.changeset.value('scheduleManually');
    this.includeNonWorkingDays = !!this.changeset.value('ignoreNonWorkingDays');

    this.date = this.changeset.value('date');
  }

  ngAfterViewInit():void {
    this
      .datepickerService
      .precedingWorkPackages$
      .pipe(
        take(1),
      )
      .subscribe((relation) => {
        this.initializeDatepicker(this.minimalDateFromPrecedingRelationship(relation));
        this.onDataChange();
      });

    this
      .dateChangedManually$
      .pipe(
        // Avoid that the manual changes are moved to the datepicker too early.
        // The debounce is chosen quite large on purpose to catch the following case:
        //   1. date is for example 2022-07-15. The user wants to set the day value  to the 19th.
        //   2. So he/she starts entering the finish date 2022-07-1 .
        //   3. This is already a valid date. Since it is before the date,the date would be changed automatically to the first without the debounce.
        //   4. The debounce gives the user enough time to type the last number "9" before the changes are converted to the datepicker and the start date would be affected.
        //
        // Debounce delay is 0 for initial display, and then set to 800
        debounce(() => timer(this.debounceDelay)),
      )
      .subscribe(() => {
        // set debounce delay to its real value
        this.debounceDelay = 800;

        // Always update the whole form to ensure that no values are lost/inconsistent
        this.updateDate(this.date);
      });
  }

  changeSchedulingMode():void {
    this.scheduleManually = !this.scheduleManually;
    this.initializeDatepicker();
    this.cdRef.detectChanges();
  }

  changeNonWorkingDays():void {
    this.includeNonWorkingDays = !this.includeNonWorkingDays;
    this.initializeDatepicker();

    // If we're single date, update the date
    if (!this.includeNonWorkingDays && this.date) {
      // Resent the current start and end dates so duration can be calculated again.
      this.dateUpdates$.next(this.date);
    }

    this.cdRef.detectChanges();
  }

  save($event:Event):void {
    $event.preventDefault();
    // Apply the changed scheduling mode if any
    this.changeset.setValue('scheduleManually', this.scheduleManually);

    // Apply the dates if they could be changed
    if (this.isSchedulable) {
      this.changeset.setValue('date', this.datepickerService.mappedDate(this.date || ''));
    }

    this.closeMe();
  }

  cancel():void {
    this.closeMe();
  }

  updateDate(val:string|null):void {
    // Expected minimal format YYYY-M-D => 8 characters OR empty
    if (val !== null && (val.length >= 8 || val.length === 0)) {
      if (this.datepickerService.validDate(val) && this.datePickerInstance) {
        const dateValue = this.datepickerService.parseDate(val) || undefined;
        this.enforceManualChangesToDatepicker(dateValue);
      }
    }
  }

  setToday():void {
    const today = this.datepickerService.parseDate(new Date()) as Date;
    this.date = this.timezoneService.formattedISODate(today);
    this.enforceManualChangesToDatepicker(today);
  }

  // eslint-disable-next-line class-methods-use-this
  reposition(element:JQuery<HTMLElement>, target:JQuery<HTMLElement>):void {
    element.position({
      my: 'left top',
      at: 'left bottom',
      of: target,
      collision: 'flipfit',
    });
  }

  /**
   * Returns whether the user can alter the dates of the work package.
   */
  get isSchedulable():boolean {
    return this.scheduleManually || !this.datepickerService.isParent;
  }

  private initializeDatepicker(minimalDate?:Date|null) {
    this.datePickerInstance?.destroy();
    this.datePickerInstance = new DatePicker(
      this.injector,
      '#flatpickr-input',
      this.date || '',
      {
        mode: 'single',
        showMonths: this.browserDetector.isMobile ? 1 : 2,
        inline: true,
        onReady: () => {
          this.reposition(jQuery(this.modalContainer.nativeElement), jQuery(`.${activeFieldContainerClassName}`));
        },
        onChange: (dates:Date[]) => {
          if (dates.length > 0) {
            this.date = this.timezoneService.formattedISODate(dates[0]);
            this.enforceManualChangesToDatepicker(dates[0]);
          }

          this.onDataChange();
          this.cdRef.detectChanges();
        },
        onDayCreate: (dObj:Date[], dStr:string, fp:flatpickr.Instance, dayElem:DayElement) => {
          if (!this.includeNonWorkingDays && this.datePickerInstance?.weekdaysService.isNonWorkingDay(dayElem.dateObj)) {
            dayElem.classList.add('flatpickr-non-working-day');
          }

          if (this.isDayDisabled(dayElem, minimalDate)) {
            dayElem.classList.add('flatpickr-disabled');
          }

          dayElem.setAttribute('data-iso-date', dayElem.dateObj.toISOString());
        },
      },
      null,
    );
  }

  private enforceManualChangesToDatepicker(enforceDate?:Date) {
    const date = this.datepickerService.parseDate(this.date || '');
    this.datepickerService.setDates(date, this.datePickerInstance, enforceDate);
  }

  private onDataChange() {
    this.onDataUpdated.emit(this.date || '');
  }

  private minimalDateFromPrecedingRelationship(relations:{ id:string, dueDate?:string, date?:string }[]):Date|null {
    if (relations.length === 0) {
      return null;
    }

    let minimalDate:Date|null = null;

    relations.forEach((relation) => {
      if (!relation.dueDate && !relation.date) {
        return;
      }

      const relationDate = relation.dueDate || relation.date;
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      const parsedRelationDate = this.datepickerService.parseDate(relationDate!);

      if (!minimalDate || minimalDate < parsedRelationDate) {
        minimalDate = parsedRelationDate === '' ? null : parsedRelationDate;
      }
    });

    return minimalDate;
  }

  private isDayDisabled(dayElement:DayElement, minimalDate?:Date|null):boolean {
    return !this.isSchedulable || (!this.scheduleManually && !!minimalDate && dayElement.dateObj <= minimalDate);
  }

  /**
   * Update the datepicker dates and properties from a form response
   * that includes derived/calculated values.
   *
   * @param form
   * @private
   */
  private updateDatesFromForm(form:FormResource):void {
    const payload = form.payload as { date:string, ignoreNonWorkingDays:boolean };

    this.date = payload.date;
    this.includeNonWorkingDays = payload.ignoreNonWorkingDays;

    const parsedDate = this.datepickerService.parseDate(payload.date) as Date;
    this.enforceManualChangesToDatepicker(parsedDate);
  }
}
