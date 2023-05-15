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
import * as moment from 'moment-timezone';

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
