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
import { BoardActionService } from 'core-app/features/boards/board/board-actions/board-action.service';
import { input } from '@openproject/reactivestates';
import {
  firstValueFrom,
  Observable,
} from 'rxjs';
import { map, take } from 'rxjs/operators';
import { Board } from 'core-app/features/boards/board/board';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Injectable()
export abstract class CachedBoardActionService extends BoardActionService {
  protected cache = input<HalResource[]>();

  protected loadValues(matching?:string):Observable<HalResource[]> {
    this
      .cache
      .putFromPromiseIfPristine(() => firstValueFrom(this.loadUncached()));

    return this
      .cache
      .values$()
      .pipe(
        map((results) => {
          if (matching) {
            return results.filter((resource) => new RegExp(matching, 'i').test(resource.name));
          }
          return results;
        }),
        take(1),
      );
  }

  addColumnWithActionAttribute(board:Board, value:HalResource):Promise<Board> {
    if (this.cache.value && !this.cache.value.find((item) => item.id === value.id)) {
      // Add the new value to the cache if it was not there before
      const newValue = [...this.cache.value, value];
      this.cache.putValue(newValue);
    }

    return super.addColumnWithActionAttribute(board, value);
  }

  protected require(id:string):Promise<HalResource> {
    this
      .cache
      .putFromPromiseIfPristine(() => firstValueFrom(this.loadUncached()));

    return firstValueFrom(this.cache.values$())
      .then((results:HalResource[]) => results.find((resource) => resource.id === id)!);
  }

  protected abstract loadUncached():Observable<HalResource[]>;
}
