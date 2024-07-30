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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  Injectable,
} from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import {
  defaultIfEmpty,
  filter,
  map,
  shareReplay,
  switchMap,
  take,
  tap,
} from 'rxjs/operators';
import {
  combineLatest,
  Observable,
  ReplaySubject,
  Subject,
} from 'rxjs';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { parseDate } from 'core-app/shared/components/datepicker/helpers/date-modal.helpers';

@Injectable()
export class DateModalRelationsService {
  private changeset$:Subject<WorkPackageChangeset> = new ReplaySubject();
  private changeset:WorkPackageChangeset;

  setChangeset(changeset:WorkPackageChangeset) {
    this.changeset$.next(changeset);
    this.changeset = changeset;
  }

  precedingWorkPackages$:Observable<{ id:string, dueDate?:string, date?:string }[]> = this.changeset$
    .pipe(
      filter((changeset) => !isNewResource(changeset.pristineResource)),
      switchMap((changeset) => this
        .apiV3Service
        .work_packages
        .signalled(
          ApiV3Filter('precedes', '=', [changeset.id]),
          [
            'elements/id',
            'elements/dueDate',
            'elements/date',
          ],
        )),
      map((collection:IHALCollection<{ id:string }>) => collection._embedded.elements || []),
      defaultIfEmpty([]),
      shareReplay(1),
    );

  followingWorkPackages$:Observable<{ id:string }[]> = this.changeset$
    .pipe(
      filter((changeset) => !isNewResource(changeset.pristineResource)),
      switchMap((changeset) => this
        .apiV3Service
        .work_packages
        .signalled(
          ApiV3Filter('follows', '=', [changeset.id]),
          ['elements/id'],
        )),
      map((collection:IHALCollection<{ id:string }>) => collection._embedded.elements || []),
      defaultIfEmpty([]),
      shareReplay(1),
    );

  hasRelations$ = combineLatest([
    this.precedingWorkPackages$,
    this.followingWorkPackages$,
  ])
    .pipe(
      map(([precedes, follows]) => precedes.length > 0 || follows.length > 0 || this.isParent || this.isChild),
    );

  constructor(
    private apiV3Service:ApiV3Service,
  ) {}

  getMinimalDateFromPreceeding():Observable<Date|null> {
    return this
      .precedingWorkPackages$
      .pipe(
        take(1),
        map((relation) => this.minimalDateFromPrecedingRelationship(relation)),
      );
  }

  private minimalDateFromPrecedingRelationship(relations:{ id:string, dueDate?:string, date?:string }[]):Date|null {
    if (relations.length === 0) {
      return null;
    }

    let minimalDate:Date|null = null;

    relations.forEach((relation) => {
      if (!relation.dueDate && !relation.date) {
        return;
      }

      const relationDate = relation.dueDate || relation.date;
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      const parsedRelationDate = parseDate(relationDate!);

      if (!minimalDate || minimalDate < parsedRelationDate) {
        minimalDate = parsedRelationDate === '' ? null : parsedRelationDate;
      }
    });

    return minimalDate;
  }

  /**
   * Determines whether the work package is a child. It does so
   * by checking the ancestors links.
   */
  get isChild():boolean {
    return this.ancestors.length > 0;
  }

  get ancestors():HalResource[] {
    const wp = this.changeset.projectedResource;
    return wp.getAncestors() || [];
  }

  /**
   * Determines whether the work package is a parent. It does so
   * by checking the children links.
   */
  get isParent():boolean {
    return this.children.length > 0;
  }

  get children():HalResource[] {
    const wp = this.changeset.projectedResource;
    return wp.children || [];
  }

  getInvolvedWorkPackageIds():Observable<string[]> {
    return combineLatest([
      this.precedingWorkPackages$,
      this.followingWorkPackages$,
    ])
      .pipe(
        map(
          ([preceding, following]) => [
            this.changeset.pristineResource,
            ...preceding,
            ...following,
            ...this.children,
            ...this.ancestors,
          ].map((el) => el.id as string),
        ),
      );
  }
}
