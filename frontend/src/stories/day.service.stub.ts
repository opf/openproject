import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import {
  ApiV3ListParameters,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { DayStore } from 'core-app/core/state/days/day.store';
import { IDay } from 'core-app/core/state/days/day.model';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';

@Injectable()
export class DayResourceServiceStub extends ResourceStoreService<IDay> {
  protected basePath():string {
    return '';
  }

  async isNonWorkingDay$(input:Date):Promise<boolean> {
    const day = input.getDay();
    return day > 5 || day === 0;
  }

  requireNonWorkingYear$(_date:Date|string):Observable<IDay[]> {
    return of([]);
  }

  requireNonWorkingYears$(_start:Date|string, _end:Date|string):Observable<IDay[]> {
    return of([]);
  }

  fetchCollection(_params:ApiV3ListParameters):Observable<IHALCollection<IDay>> {
    return of({
      _type: 'Collection',
      count: 0,
      pageSize: 10,
      offset: 0,
      total: 0,
      _embedded: {
        elements: [],
      },
    });
  }

  protected createStore():ResourceStore<IDay> {
    return new DayStore();
  }
}
