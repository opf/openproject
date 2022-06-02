import { Injectable } from '@angular/core';
import {
  map,
  switchMap,
  tap,
} from 'rxjs/operators';
import {
  EMPTY,
  Observable,
} from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { HttpClient } from '@angular/common/http';
import {
  extendCollectionElementsWithId,
  insertCollectionIntoState,
} from 'core-app/core/state/collection-store';
import { WeekdayStore } from 'core-app/core/state/days/weekday.store';
import { IWeekday } from 'core-app/core/state/days/weekday.model';
import {
  CollectionStore,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';

@Injectable()
export class WeekdayResourceService extends ResourceCollectionService<IWeekday> {
  private get weekdaysPath():string {
    return this
      .apiV3Service
      .days
      .week
      .path;
  }

  constructor(
    private http:HttpClient,
    private apiV3Service:ApiV3Service,
  ) {
    super();
  }

  require():Observable<IWeekday[]> {
    return this
      .query
      .selectHasCache()
      .pipe(
        switchMap((hasCache) => (hasCache ? EMPTY : this.fetchWeekdays())),
        switchMap(() => this.query.selectAll()),
      );
  }

  private fetchWeekdays():Observable<IHALCollection<IWeekday>> {
    const collectionURL = 'all'; // We load all weekdays

    return this
      .http
      .get<IHALCollection<IWeekday>>(this.weekdaysPath)
      .pipe(
        map((collection) => extendCollectionElementsWithId(collection)),
        tap((collection) => insertCollectionIntoState(this.store, collection, collectionURL)),
      );
  }

  protected createStore():CollectionStore<IWeekday> {
    return new WeekdayStore();
  }
}
