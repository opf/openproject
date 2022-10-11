import { Injectable } from '@angular/core';
import {
  finalize,
  map,
  tap,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import {
  ApiV3ListFilter,
  ApiV3ListParameters,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  collectionKey,
  extendCollectionElementsWithId,
  insertCollectionIntoState,
  setCollectionLoading,
} from 'core-app/core/state/collection-store';
import { DayStore } from 'core-app/core/state/days/day.store';
import { IDay } from 'core-app/core/state/days/day.model';
import {
  CollectionStore,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';

@Injectable()
export class DayResourceService extends ResourceCollectionService<IDay> {
  protected basePath():string {
    return this
      .apiV3Service
      .days
      .path;
  }

  isNonWorkingDay$(input:Date):Observable<boolean> {
    const date = moment(input).format('YYYY-MM-DD');

    return this
      .requireNonWorkingYear$(input)
      .pipe(
        map((days) => days.findIndex((day:IDay) => !day.working && day.date === date) !== -1),
      );
  }

  requireNonWorkingYear$(date:Date):Observable<IDay[]> {
    const from = moment(date).startOf('year').format('YYYY-MM-DD');
    const to = moment(date).endOf('year').format('YYYY-MM-DD');

    const filters:ApiV3ListFilter[] = [
      ['date', '<>d', [from, to]],
      ['working', '=', ['f']],
    ];

    return this.require({ filters });
  }

  fetchCollection(params:ApiV3ListParameters):Observable<IHALCollection<IDay>> {
    const collectionURL = collectionKey(params);

    setCollectionLoading(this.store, collectionURL, true);

    return this
      .http
      .get<IHALCollection<IDay>>(this.basePath() + collectionURL)
      .pipe(
        map((collection) => extendCollectionElementsWithId(collection)),
        tap((collection) => insertCollectionIntoState(this.store, collection, collectionURL)),
        finalize(() => setCollectionLoading(this.store, collectionURL, false)),
      );
  }

  protected createStore():CollectionStore<IDay> {
    return new DayStore();
  }
}
