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
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
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
  require():Observable<IWeekday[]> {
    return this
      .query
      .selectHasCache()
      .pipe(
        switchMap((hasCache) => (hasCache ? EMPTY : this.fetchWeekdays())),
        switchMap(() => this.query.selectAll()),
      );
  }

  protected fetchWeekdays():Observable<IHALCollection<IWeekday>> {
    const collectionURL = 'all'; // We load all weekdays

    return this
      .http
      .get<IHALCollection<IWeekday>>(this.basePath())
      .pipe(
        map((collection) => extendCollectionElementsWithId(collection)),
        tap((collection) => insertCollectionIntoState(this.store, collection, collectionURL)),
      );
  }

  protected createStore():CollectionStore<IWeekday> {
    return new WeekdayStore();
  }

  protected basePath():string {
    return this
      .apiV3Service
      .days
      .week
      .path;
  }
}
