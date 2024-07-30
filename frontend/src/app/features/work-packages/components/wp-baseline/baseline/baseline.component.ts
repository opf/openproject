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
  Component,
  EventEmitter,
  HostBinding,
  Input,
  OnInit,
  Output,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { Observable } from 'rxjs';
import {
  DEFAULT_TIMESTAMP,
  WorkPackageViewBaselineService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { validDate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';
import {
  baselineFilterFromValue,
  getPartsFromTimestamp,
  offsetToUtcString,
} from 'core-app/features/work-packages/components/wp-baseline/baseline-helpers';
import * as moment from 'moment-timezone';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { enterpriseDocsUrl } from 'core-app/core/setup/globals/constants.const';
import { DayElement } from 'flatpickr/dist/types/instance';

const DEFAULT_SELECTED_TIME = '08:00';

@Component({
  selector: 'op-baseline',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './baseline.component.html',
  styleUrls: ['./baseline.component.sass'],
})
export class OpBaselineComponent extends UntilDestroyedMixin implements OnInit {
  @HostBinding('class.op-baseline') className = true;

  @Output() submitted = new EventEmitter<void>();

  @Input() showActionBar? = false;

  @Input() visible = true;

  public mappedSelectedDate:string|null;

  public nonWorkingDays$:Observable<IDay[]> = this.wpTableBaseline.nonWorkingDays$;

  public selectedDates:string[];

  public selectedTimes:string[];

  public selectedOffsets:string[];

  public userTimezone:string;

  public userOffset:string;

  public selectedFilter:string|null;

  public selectedTimezoneFormattedTime:string[];

  public tooltipPosition = SpotDropAlignmentOption.TopRight;

  eeShowBanners = this.Banner.eeShowBanners;

  public text = {
    toggle_title: this.I18n.t('js.baseline.toggle_title'),
    drop_down_none_option: this.I18n.t('js.baseline.drop_down.none'),
    header_description: this.I18n.t('js.baseline.header_description'),
    enterprise_header_description: this.I18n.t('js.baseline.enterprise_header_description'),
    clear: this.I18n.t('js.baseline.clear'),
    apply: this.I18n.t('js.baseline.apply'),
    show_changes_since: this.I18n.t('js.baseline.show_changes_since'),
    from: this.I18n.t('js.baseline.from'),
    to: this.I18n.t('js.baseline.to'),
    date: this.I18n.t('js.label_date'),
    time: this.I18n.t('js.baseline.time'),
    today: this.I18n.t('js.label_today'),
    moreInfoLink: enterpriseDocsUrl.website,
    more_info_text: this.I18n.t('js.admin.enterprise.upsale.more_info'),
    help_description: this.I18n.t('js.baseline.help_description'),
    baseline_comparison: this.I18n.t('js.baseline.baseline_comparison'),
    time_description: (i:number) => {
      const date = this.selectedDates[i];
      const time = this.selectedTimes[i];
      const offset = this.selectedOffsets[i];

      if (!date || !time) {
        return '';
      }

      const formatted = moment(`${date}T${time}${offset}`)
        .tz(this.userTimezone);

      const formattedDate = formatted.format(this.timezoneService.getDateFormat());
      const formattedTime = formatted.format(this.timezoneService.getTimeFormat());
      return this.I18n.t('js.baseline.time_description', {
        datetime: `${formattedDate} ${formattedTime}`,
      });
    },
  };

  public baselineAvailableValues = [
    {
      value: 'oneDayAgo',
      title: this.I18n.t('js.baseline.drop_down.yesterday'),
    },
    {
      value: 'lastWorkingDay',
      title: this.I18n.t('js.baseline.drop_down.last_working_day'),
    },
    {
      value: 'oneWeekAgo',
      title: this.I18n.t('js.baseline.drop_down.last_week'),
    },
    {
      value: 'oneMonthAgo',
      title: this.I18n.t('js.baseline.drop_down.last_month'),
    },
    {
      value: 'aSpecificDate',
      title: this.I18n.t('js.baseline.drop_down.a_specific_date'),
    },
    {
      value: 'betweenTwoSpecificDates',
      title: this.I18n.t('js.baseline.drop_down.between_two_specific_dates'),
    },
  ];

  constructor(
    readonly I18n:I18nService,
    readonly wpTableBaseline:WorkPackageViewBaselineService,
    readonly halResourceService:HalResourceService,
    readonly weekdaysService:WeekdayService,
    readonly daysService:DayResourceService,
    readonly timezoneService:TimezoneService,
    readonly configuration:ConfigurationService,
    readonly Banner:BannersService,
  ) {
    super();
  }

  public ngOnInit():void {
    this.userTimezone = this.timezoneService.userTimezone();
    this.userOffset = moment().tz(this.userTimezone).format('Z');
    this.resetSelection();

    if (this.wpTableBaseline.isActive()) {
      this.filterChange(baselineFilterFromValue(this.wpTableBaseline.current));
      this.wpTableBaseline.current.forEach((value, i) => {
        const parts = getPartsFromTimestamp(value);
        if (parts) {
          this.selectedDates[i] = this.selectedDates[i] ? this.selectedDates[i] : parts.date;
          this.selectedTimes[i] = parts.time;
          this.selectedOffsets[i] = parts.offset;
        }
      });
    }

    this.wpTableBaseline
      .pristine$()
      .subscribe((timestamps) => {
        if (_.isEqual(timestamps, [DEFAULT_TIMESTAMP])) {
          this.resetSelection();
          this.wpTableBaseline.disable();
        }
      });
  }

  public resetSelection():void {
    this.selectedTimes = [DEFAULT_SELECTED_TIME, DEFAULT_SELECTED_TIME];
    this.selectedDates = ['', ''];
    this.selectedFilter = null;
    this.mappedSelectedDate = null;
    this.selectedOffsets = [this.userOffset, this.userOffset];
  }

  public setToday(key:string):void {
    const today = moment().format('YYYY-MM-DD');
    const from = key === 'from' ? today : this.selectedDates[0];
    // When setting the "from" date to today, the "to" date must also be set to today,
    // because we do not allow future dates, meaning "to" cannot be anything else but today.
    const to = today;
    this.dateChange([from, to]);
  }

  public onSubmit(e:Event):void {
    e.preventDefault();
    this.onSave();
  }

  public onSave() {
    this.wpTableBaseline.update(this.buildBaselineFilter());
    this.submitted.emit();
  }

  public mappedOffset(offset:string) {
    return offsetToUtcString(offset);
  }

  public timesChange(value:string[]):void {
    this.selectedTimes = value;
  }

  public dateChange(values:string[]):void {
    if (_.every(values, validDate)) {
      this.selectedDates = values;
    }
  }

  public filterChange(value:string|null):void {
    this.resetSelection();
    this.selectedFilter = value;
    switch (value) {
      case 'oneDayAgo':
        this.updateDateValues(this.wpTableBaseline.yesterdayDate());
        break;
      case 'lastWorkingDay':
        this.updateDateValues(this.wpTableBaseline.lastWorkingDate());
        break;
      case 'oneWeekAgo':
        this.updateDateValues(this.wpTableBaseline.lastweekDate());
        break;
      case 'oneMonthAgo':
        this.updateDateValues(this.wpTableBaseline.lastMonthDate());
        break;
      default:
        this.mappedSelectedDate = null;
        break;
    }
  }

  public futureDateComparer():(dayElem:DayElement) => boolean {
    const now = moment();
    return (dayElem:DayElement) => moment(dayElem.dateObj).isAfter(now, 'days');
  }

  private updateDateValues(date:string) {
    this.mappedSelectedDate = this.timezoneService.formattedDate(date);
    this.dateChange([date]);
  }

  private buildBaselineFilter():string[] {
    switch (this.selectedFilter) {
      case 'oneDayAgo':
      case 'oneWeekAgo':
      case 'oneMonthAgo':
      case 'lastWorkingDay':
        return [this.buildFilterString(0), DEFAULT_TIMESTAMP];
      case 'aSpecificDate':
        return [this.buildISOString(0), DEFAULT_TIMESTAMP];
      case 'betweenTwoSpecificDates':
        return [
          this.buildISOString(0),
          this.buildISOString(1),
        ];
      default:
        return [DEFAULT_TIMESTAMP];
    }
  }

  private buildISOString(i:number):string {
    return `${this.selectedDates[i]}T${this.selectedTimes[i]}${this.selectedOffsets[i]}`;
  }

  private buildFilterString(i:number):string {
    const timeWithOffset = `${this.selectedTimes[i]}${this.selectedOffsets[i]}`;
    return `${this.selectedFilter as string}@${timeWithOffset}`;
  }
}
