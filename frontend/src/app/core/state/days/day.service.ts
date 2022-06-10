import { Injectable } from '@angular/core';
import {
  map,
  tap,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { HttpClient } from '@angular/common/http';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  collectionKey,
  extendCollectionElementsWithId,
  insertCollectionIntoState,
} from 'core-app/core/state/collection-store';
import { DayStore } from 'core-app/core/state/days/day.store';
import { IDay } from 'core-app/core/state/days/day.model';
import {
  CollectionStore,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';

@Injectable()
export class DayResourceService extends ResourceCollectionService<IDay> {
  private get daysPath():string {
    return this
      .apiV3Service
      .days
      .path;
  }

  constructor(
    private http:HttpClient,
    private apiV3Service:ApiV3Service,
  ) {
    super();
  }

  fetchDays(params:ApiV3ListParameters):Observable<IHALCollection<IDay>> {
    const collectionURL = collectionKey(params);

    return this
      .http
      .get<IHALCollection<IDay>>(this.daysPath + collectionURL)
      .pipe(
        map((collection) => extendCollectionElementsWithId(collection)),
        tap((collection) => insertCollectionIntoState(this.store, collection, collectionURL)),
      );
  }

  protected createStore():CollectionStore<IDay> {
    return new DayStore();
  }
}
