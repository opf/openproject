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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable } from '@angular/core';
import { map } from 'rxjs/operators';
import { firstValueFrom, Observable } from 'rxjs';

import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { DayStore } from 'core-app/core/state/days/day.store';
import { IDay } from 'core-app/core/state/days/day.model';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';
import moment from 'moment-timezone';

@Injectable()
export class DayResourceService extends ResourceStoreService<IDay> {
  protected basePath():string {
    return this
      .apiV3Service
      .days
      .nonWorkingDays
      .path;
  }

  isNonWorkingDay$(input:Date):Promise<boolean> {
    const date = moment(input).format('YYYY-MM-DD');

    return firstValueFrom(
      this
        .requireNonWorkingYear$(input)
        .pipe(
          map((days) => days.findIndex((day:IDay) => day.date === date) !== -1),
        ),
    );
  }

  requireNonWorkingYear$(date:Date|string):Observable<IDay[]> {
    const from = moment(date).startOf('year').format('YYYY-MM-DD');
    const to = moment(date).endOf('year').format('YYYY-MM-DD');

    const filters:ApiV3ListFilter[] = [
      ['date', '<>d', [from, to]],
    ];

    return this.requireCollection({ filters });
  }

  requireNonWorkingYears$(start:Date|string, end:Date|string):Observable<IDay[]> {
    const from = moment(start).startOf('year').format('YYYY-MM-DD');
    const to = moment(end).endOf('year').format('YYYY-MM-DD');

    const filters:ApiV3ListFilter[] = [
      ['date', '<>d', [from, to]],
    ];

    return this.requireCollection({ filters });
  }

  protected createStore():ResourceStore<IDay> {
    return new DayStore();
  }
}
