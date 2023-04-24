// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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
  Component,
  HostBinding,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { IDay } from 'core-app/core/state/days/day.model';
import { take } from 'rxjs/operators';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Component({
  selector: 'op-baseline',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './baseline.component.html',
  styleUrls: ['./baseline.component.sass'],
})
export class OpBaselineComponent extends UntilDestroyedMixin implements AfterViewInit {
  @HostBinding('class.op-baseline') className = true;

  public opened = false;

  public dropDownDescription = '';

  public nonWorkingDays:IDay[] = [];

  public selectedDate = '';

  public selectedTimezoneFormattedTime = '';

  public filterSelected = false;

  public timeZoneSelected = false;

  public daysNumber = 0;

  public tooltipPosition = SpotDropAlignmentOption.BottomRight;

  public text = {
    toggle_title: this.I18n.t('js.baseline.toggle_title'),
    header_description: this.I18n.t('js.baseline.header_description'),
    clear: this.I18n.t('js.baseline.clear'),
    apply: this.I18n.t('js.baseline.apply'),
    show_changes_since: this.I18n.t('js.baseline.show_changes_since'),
    time: this.I18n.t('js.baseline.time'),
    help_description: this.I18n.t('js.baseline.help_description'),
    timeZone: this.configuration.isTimezoneSet() ? moment().tz(this.configuration.timezone()).zoneAbbr() : 'local',
    time_description: () => this.I18n.t('js.baseline.time_description', { time: this.selectedTimezoneFormattedTime, days: this.daysNumber }),
  };

  public baselineAvailableValues = [
    {
      value: '0',
      title: this.I18n.t('js.baseline.drop_down.none'),
    },
    {
      value: '1',
      title: this.I18n.t('js.baseline.drop_down.yesterday'),
    },
    {
      value: '2',
      title: this.I18n.t('js.baseline.drop_down.last_working_day'),
    },
    {
      value: '3',
      title: this.I18n.t('js.baseline.drop_down.last_week'),
    },
    {
      value: '4',
      title: this.I18n.t('js.baseline.drop_down.last_month'),
    },
    {
      value: '5',
      title: this.I18n.t('js.baseline.drop_down.a_specific_date'),
    },
    {
      value: '6',
      title: this.I18n.t('js.baseline.drop_down.between_two_specific_dates'),
    },
  ];

  public query$ = this.wpTableFilters.querySpace.query.values$();

  constructor(
    readonly I18n:I18nService,
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly halResourceService:HalResourceService,
    private weekdaysService:WeekdayService,
    private daysService:DayResourceService,
    readonly timezoneService:TimezoneService,
    private configuration:ConfigurationService,
  ) {
    super();
  }

  async ngAfterViewInit():Promise<void> {
    await this.requireNonWorkingDaysOfTwoYears();
  }

  public toggleOpen():void {
    this.opened = !this.opened;
  }

  public clearSelection():void {
  }

  public onSubmit(e:Event):void {
    e.preventDefault();

    this.close();
  }

  public close():void {
    this.opened = false;
  }

  public yesterdayDate():string {
    const today = new Date();
    this.daysNumber = -1;

    today.setDate(today.getDate() - 1);
    this.selectedDate = moment(today).format('YYYY-MM-DD');
    return moment(today).format('ddd, YYYY-MM-DD');
  }

  public lastMonthDate():string {
    const today = new Date();
    const lastMonthDate = new Date(today);

    lastMonthDate.setMonth(today.getMonth() - 1);
    this.selectedDate = moment(lastMonthDate).format('YYYY-MM-DD');
    this.daysNumber = moment(lastMonthDate).diff(moment(today), 'days');
    return moment(today).format('ddd, YYYY-MM-DD');
  }

  public lastweekDate():string {
    const today = new Date();
    this.daysNumber = -7;
    today.setDate(today.getDate() - 7);
    this.selectedDate = moment(today).format('YYYY-MM-DD');
    return moment(today).format('ddd, YYYY-MM-DD');
  }

  async requireNonWorkingDaysOfTwoYears() {
    const today = new Date();
    const lastYear = new Date(today);
    lastYear.setFullYear(today.getFullYear() - 1);
    this.nonWorkingDays = await this
      .daysService
      .requireNonWorkingYears$(lastYear, today)
      .pipe(take(1))
      .toPromise()?? [];
  }

  isNonWorkingDay(date:Date|string):boolean {
    const formatted = moment(date).format('YYYY-MM-DD');
    return (this.nonWorkingDays.findIndex((el) => el.date === formatted) !== -1);
  }

  public lastWorkingDate():string {
    const today = new Date();
    const yesterday = new Date(today);
    let lastWorkingDay = '';

    yesterday.setDate(today.getDate() - 1);
    while (lastWorkingDay === '') {
      if (this.isNonWorkingDay(yesterday) || this.weekdaysService.isNonWorkingDay(yesterday)) {
        yesterday.setDate(yesterday.getDate() - 1);
        continue;
      } else {
        lastWorkingDay = moment(yesterday).format('ddd, YYYY-MM-DD');
        this.selectedDate = moment(yesterday).format('YYYY-MM-DD');
        this.daysNumber = moment(yesterday).diff(moment(today), 'days');
        break;
      }
    }

    return lastWorkingDay;
  }

  public timeChange(value:string):void {
    const timeZone = this.configuration.isTimezoneSet();
    if (timeZone) {
      this.timeZoneSelected = true;
      const dateTime= `${this.selectedDate}  ${value}`;
      this.selectedTimezoneFormattedTime = this.timezoneService.formattedTime(dateTime);
    }
  }

  public filterChange(value:string):void {
    if (value !== '0') {
      this.filterSelected = true;
      switch (value) {
        case '1':
          this.dropDownDescription = this.yesterdayDate();
          break;
        case '2':
          this.dropDownDescription=this.lastWorkingDate();
          break;
        case '3':
          this.dropDownDescription = this.lastweekDate();
          break;
        case '4':
          this.dropDownDescription = this.lastMonthDate();
          break;
        default:
          this.dropDownDescription = '';
          break;
      }
    } else {
      this.filterSelected = false;
      this.dropDownDescription = '';
    }
  }
}
