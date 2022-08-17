// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
  Inject,
  Injectable,
} from '@angular/core';
import {
  DateFields,
  DateKeys,
} from 'core-app/shared/components/datepicker/datepicker.modal';
import { DatePicker } from 'core-app/shared/components/op-date-picker/datepicker';
import { DateOption } from 'flatpickr/dist/types/options';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import {
  defaultIfEmpty,
  filter,
  map,
  shareReplay,
  switchMap,
} from 'rxjs/operators';
import {
  combineLatest,
  Observable,
  of,
} from 'rxjs';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

@Injectable()
export class DatepickerModalService {
  currentlyActivatedDateField:DateFields;

  private changeset:WorkPackageChangeset = this.locals.changeset as WorkPackageChangeset;

  precedingWorkPackages$:Observable<{ id:string, dueDate?:string, date?:string }[]> = of(this.changeset)
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

  followingWorkPackages$:Observable<{ id:string }[]> = of(this.changeset)
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
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    private apiV3Service:ApiV3Service,
  ) {}

  /**
   * Determines whether the work package is a child. It does so
   * by checking the ancestors links.
   */
  get isChild():boolean {
    return this.ancestors.length > 0;
  }

  get ancestors():HalResource[] {
    const wp = this.changeset.projectedResource;
    return wp.ancestors || [];
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

  /**
   * Map the date to the internal format,
   * setting to null if it's empty.
   * @param date
   */
  // eslint-disable-next-line class-methods-use-this
  mappedDate(date:string):string|null {
    return date === '' ? null : date;
  }

  // eslint-disable-next-line class-methods-use-this
  parseDate(date:Date|string):Date|'' {
    if (date instanceof Date) {
      return new Date(date.setHours(0, 0, 0, 0));
    }
    if (date === '') {
      return '';
    }
    return new Date(moment(date).toDate().setHours(0, 0, 0, 0));
  }

  // eslint-disable-next-line class-methods-use-this
  validDate(date:Date|string):boolean {
    return (date instanceof Date)
      || (date === '')
      || !!new Date(date).valueOf();
  }

  areDatesEqual(firstDate:Date|string, secondDate:Date|string):boolean {
    const parsedDate1 = this.parseDate(firstDate);
    const parsedDate2 = this.parseDate(secondDate);

    if ((typeof (parsedDate1) === 'string') || (typeof (parsedDate2) === 'string')) {
      return false;
    }
    return parsedDate1.getTime() === parsedDate2.getTime();
  }

  setCurrentActivatedField(val:DateFields):void {
    this.currentlyActivatedDateField = val;
  }

  toggleCurrentActivatedField():void {
    this.currentlyActivatedDateField = this.currentlyActivatedDateField === 'start' ? 'end' : 'start';
  }

  isStateOfCurrentActivatedField(val:DateFields):boolean {
    return this.currentlyActivatedDateField === val;
  }

  setDates(dates:DateOption|DateOption[], datePicker:DatePicker, enforceDate?:Date):void {
    const { currentMonth } = datePicker.datepickerInstance;
    const { currentYear } = datePicker.datepickerInstance;
    datePicker.setDates(dates);

    if (enforceDate) {
      const enforcedMonth = enforceDate.getMonth();
      const enforcedYear = enforceDate.getFullYear();
      const monthDiff = enforcedMonth - currentMonth + 12 * (enforcedYear - currentYear);

      // Because of the two-month layout we only have to update the calendar
      // if the month is further in the past/future than the one additional month that is shown anyway
      if (Math.abs(monthDiff) > 1) {
        datePicker.datepickerInstance.currentMonth = enforcedMonth;
        datePicker.datepickerInstance.currentYear = enforcedYear;
      } else {
        this.keepCurrentlyActiveMonth(datePicker, currentMonth, currentYear);
      }
    } else {
      this.keepCurrentlyActiveMonth(datePicker, currentMonth, currentYear);
    }

    datePicker.datepickerInstance.redraw();
  }

  private keepCurrentlyActiveMonth(datePicker:DatePicker, currentMonth:number, currentYear:number) {
    // Keep currently active month and avoid jump because of two-month layout
    datePicker.datepickerInstance.currentMonth = currentMonth;
    datePicker.datepickerInstance.currentYear = currentYear;
  }
}
