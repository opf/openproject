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
} from 'core-app/core/state/resource-store';
import { WeekdayStore } from 'core-app/core/state/days/weekday.store';
import { IWeekday } from 'core-app/core/state/days/weekday.model';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';

@Injectable()
export class WeekdayResourceService extends ResourceStoreService<IWeekday> {
  requireCollection():Observable<IWeekday[]> {
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

  protected createStore():ResourceStore<IWeekday> {
    return new WeekdayStore();
  }

  protected basePath():string {
    return this.apiV3Service.days.week.path;
  }
}
