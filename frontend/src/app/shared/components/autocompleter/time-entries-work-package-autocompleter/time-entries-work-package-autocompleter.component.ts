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

import { ChangeDetectionStrategy, Component, forwardRef, OnInit, inject } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import {
  OpAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { map, switchMap } from 'rxjs/operators';
import { Observable } from 'rxjs';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { IAPIFilter } from 'core-app/shared/components/autocompleter/op-autocompleter/typings';
import { HalResourceSortingService } from 'core-app/features/hal/services/hal-resource-sorting.service';
import {
  TimeEntriesWorkPackageAutocompleterTemplateComponent,
} from 'core-app/shared/components/autocompleter/time-entries-work-package-autocompleter/time-entries-work-package-autocompleter-template.component';

export type TimeEntryWorkPackageAutocompleterMode = 'all'|'recent';

const RECENT_TIME_ENTRIES_MAGIC_NUMBER = 30;

@Component({
  templateUrl: '../op-autocompleter/op-autocompleter.component.html',
  selector: 'op-time-entries-work-package-autocompleter',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => TimeEntriesWorkPackageAutocompleterComponent),
      multi: true,
    },
  ],
  standalone: false,
})
export class TimeEntriesWorkPackageAutocompleterComponent extends OpAutocompleterComponent implements OnInit, ControlValueAccessor {
  public mode:TimeEntryWorkPackageAutocompleterMode = 'all';

  readonly halSorting = inject(HalResourceSortingService);

  labelAll = this.I18n.t('js.label_all');
  labelRecent = this.I18n.t('js.label_recent');

  private recentWorkPackageIds:string[];

  getOptionsFn = this.loadAllowedValues.bind(this);

  ngOnInit():void {
    super.ngOnInit();
    this.applyTemplates(TimeEntriesWorkPackageAutocompleterTemplateComponent);
  }

  changeMode(newMode:TimeEntryWorkPackageAutocompleterMode) {
    this.mode = newMode;

    if (this.typeahead) {
      const lastValue = this.typeahead?.value;
      this.typeahead?.next(' '); // Reset value
      this.typeahead?.next(lastValue);
    }

    this.cdRef.detectChanges();
  }

  // We fetch the last RECENT_TIME_ENTRIES_MAGIC_NUMBER time entries by that user. We then use it to fetch the work packages
  // associated with the time entries so that we have the most recent work packages the user logged time on.
  // As a worst case, the user logged RECENT_TIME_ENTRIES_MAGIC_NUMBER times on one work package so we can not guarantee to actually have
  // a fixed number returned.
  protected loadAllowedValues(query:string):Observable<HalResource[]> {
    if (!this.recentWorkPackageIds) {
      return this
          .apiV3Service
          .time_entries
          .list({
            filters: [['user_id', '=', ['me']]],
            sortBy: [['updated_at', 'desc']],
            pageSize: RECENT_TIME_ENTRIES_MAGIC_NUMBER,
          })
        .pipe(
          switchMap((collection:CollectionResource<TimeEntryResource>) => {
            this.recentWorkPackageIds = collection
              .elements
              .filter((timeEntry) => timeEntry.workPackage?.href)
              .map((timeEntry) => idFromLink(timeEntry.workPackage.href))
              .filter((v, i, a) => a.indexOf(v) === i);

            return this.loadWorkPackages(query);
          }),
        );
    }

    return this.loadWorkPackages(query);
  }

  protected get modeSpecificFilters():IAPIFilter[] {
    const base = this.filters ?? [];
    const isRecent = this.mode === 'recent';
    if (isRecent && this.recentWorkPackageIds.length > 0) {
      return [...base, { name: 'id', operator: '=', values: this.recentWorkPackageIds }];
    }

    return base;
  }

  protected loadWorkPackages(query:string):Observable<HalResource[]> {
    return this.opAutocompleterService
      .loadFromUrl(
        this.url,
        query,
        this.resource,
        this.modeSpecificFilters,
        this.searchKey,
        (this.mode === 'recent'), // allow empty typeahead for recent page, as this will list most recent WPs
      )
      .pipe(map((workPackages) => this.sortValues(workPackages)));
  }

  protected sortValues(availableValues:HalResource[]) {
    if (this.mode === 'recent') {
      return this.sortValuesByRecentIds(availableValues);
    }
    return this.halSorting.sort(availableValues);
  }

  protected sortValuesByRecentIds(availableValues:HalResource[]) {
    return availableValues
      .sort((a, b) => this.recentWorkPackageIds.indexOf(a.id!) - this.recentWorkPackageIds.indexOf(b.id!));
  }
}
