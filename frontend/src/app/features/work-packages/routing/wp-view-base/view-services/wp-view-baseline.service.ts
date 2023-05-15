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

import { Injectable } from '@angular/core';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { States } from 'core-app/core/states/states.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageQueryStateService } from './wp-view-base.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { Observable } from 'rxjs';
import { IDay } from 'core-app/core/state/days/day.model';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IWorkPackageTimestamp } from 'core-app/features/hal/resources/work-package-timestamp-resource';

export const DEFAULT_TIMESTAMP = 'PT0S';

@Injectable()
export class WorkPackageViewBaselineService extends WorkPackageQueryStateService<string[]> {
  constructor(
    protected readonly states:States,
    protected readonly querySpace:IsolatedQuerySpace,
    protected readonly pathHelper:PathHelperService,
    protected readonly configurationService:ConfigurationService,
    protected readonly timezoneService:TimezoneService,
    protected readonly weekdaysService:WeekdayService,
    protected readonly daysService:DayResourceService,
  ) {
    super(querySpace);
  }

  public nonWorkingDays:IDay[] = [];

  public daysNumber = 0;

  public nonWorkingDays$:Observable<IDay[]> = this.requireNonWorkingDaysOfTwoYears();

  public selectedDate = '';

  public yesterdayDate():string {
    const today = new Date();
    this.daysNumber = -1;

    today.setDate(today.getDate() - 1);
    this.selectedDate = this.timezoneService.formattedDate(today.toString());
    return this.selectedDate;
  }

  public lastMonthDate():string {
    const today = new Date();
    const lastMonthDate = new Date(today);

    lastMonthDate.setMonth(today.getMonth() - 1);
    this.selectedDate = this.timezoneService.formattedDate(lastMonthDate.toString());
    this.daysNumber = moment(lastMonthDate).diff(moment(today), 'days');
    return this.selectedDate;
  }

  public lastWeekDate():string {
    const today = new Date();
    this.daysNumber = -7;
    today.setDate(today.getDate() - 7);
    this.selectedDate = this.timezoneService.formattedDate(today.toString());
    return this.selectedDate;
  }

  requireNonWorkingDaysOfTwoYears() {
    const today = new Date();
    const lastYear = new Date(today);
    lastYear.setFullYear(today.getFullYear() - 1);
    const nonWorkingDays$= this
      .daysService
      .requireNonWorkingYears$(lastYear, today);

    nonWorkingDays$.subscribe((nonWorkingDays) => {
      this.nonWorkingDays =nonWorkingDays;
    });

    return nonWorkingDays$;
  }

  isNonWorkingDay(date:Date|string):boolean {
    const formatted = moment(date).format('YYYY-MM-DD');
    return (this.nonWorkingDays.findIndex((el) => el.date === formatted) !== -1);
  }

  public lastWorkingDate():string {
    const today = new Date();
    const yesterday = new Date(today);
    this.selectedDate = '';
    yesterday.setDate(today.getDate() - 1);
    while (this.selectedDate === '') {
      if (this.isNonWorkingDay(yesterday) || this.weekdaysService.isNonWorkingDay(yesterday)) {
        yesterday.setDate(yesterday.getDate() - 1);
        continue;
      } else {
        this.selectedDate = this.timezoneService.formattedDate(yesterday.toString());
        this.daysNumber = moment(yesterday).diff(moment(today), 'days');
        break;
      }
    }
    return this.selectedDate;
  }

  public isActive():boolean {
    if (!this.configurationService.activeFeatureFlags.includes('showChanges')) {
      return false;
    }

    return this.current.length >= 1 && this.current[0] !== DEFAULT_TIMESTAMP;
  }

  public isChanged(workPackage:WorkPackageResource, attribute:string):boolean {
    const timestamps = workPackage.attributesByTimestamp || [];
    return this.isActive() && timestamps.length >= 1 && !!timestamps[0][attribute as keyof IWorkPackageTimestamp];
  }

  public valueFromQuery(query:QueryResource):string[] {
    return query.timestamps;
  }

  public hasChanged(query:QueryResource) {
    return !_.isEqual(query.timestamps, this.current);
  }

  public applyToQuery(query:QueryResource):boolean {
    query.timestamps = [...this.current];

    return true;
  }

  public disable() {
    this.update([DEFAULT_TIMESTAMP]);
  }

  public get current():string[] {
    return this.lastUpdatedState.getValueOr([DEFAULT_TIMESTAMP]);
  }
}
