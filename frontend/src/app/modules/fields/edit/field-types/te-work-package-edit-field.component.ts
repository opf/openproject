//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Component } from "@angular/core";
import { WorkPackageEditFieldComponent } from "core-app/modules/fields/edit/field-types/work-package-edit-field.component";
import { ApiV3FilterBuilder } from "core-components/api/api-v3/api-v3-filter-builder";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import {
  TimeEntryWorkPackageAutocompleterComponent,
  TimeEntryWorkPackageAutocompleterMode
} from "core-app/modules/autocompleter/te-work-package-autocompleter/te-work-package-autocompleter.component";

const RECENT_TIME_ENTRIES_MAGIC_NUMBER = 30;

@Component({
  templateUrl: './work-package-edit-field.component.html'
})
export class TimeEntryWorkPackageEditFieldComponent extends WorkPackageEditFieldComponent {
  @InjectField() apiV3Service:APIV3Service;

  private recentWorkPackageIds:string[];

  protected initialize() {
    super.initialize();

    // For reasons beyond me, the referenceOutputs variable is not defined at first when editing
    // existing values.
    if (this.referenceOutputs) {
      this.referenceOutputs['modeSwitch'] = (mode:TimeEntryWorkPackageAutocompleterMode) => {
        this.valuesLoaded = false;
        const lastValue = this.requests.lastRequestedValue!;

        // Hack to provide a new value to "reset" the input.
        // Only the second input is actually processed as the input is debounced.
        this.requests.input$.next('_/&"()____');
        this.requests.input$.next(lastValue);
      };
    }
  }

  public autocompleterComponent() {
    return TimeEntryWorkPackageAutocompleterComponent;
  }

  // Although the schema states the work packages to not be required,
  // as time entries can also be assigned to a project, we want to only assign
  // time entries to work packages and thus require a value.
  // The back end will have to be changed in due time but not as long as there is still a rails based
  // time entry view in the application.
  protected isRequired() {
    return true;
  }

  // We fetch the last RECENT_TIME_ENTRIES_MAGIC_NUMBER time entries by that user. We then use it to fetch the work packages
  // associated with the time entries so that we have the most recent work packages the user logged time on.
  // As a worst case, the user logged RECENT_TIME_ENTRIES_MAGIC_NUMBER times on one work package so we can not guarantee to actually have
  // a fixed number returned.
  protected loadAllowedValues(query?:string) {
    if (!this.recentWorkPackageIds) {
      return this
        .apiV3Service
        .time_entries
        .list({ filters: [['user_id', '=', ['me']]], sortBy: [["updated_at", "desc"]], pageSize: RECENT_TIME_ENTRIES_MAGIC_NUMBER })
        .toPromise()
        .then(collection => {
          this.recentWorkPackageIds = collection
            .elements
            .map((timeEntry) => timeEntry.workPackage.idFromLink)
            .filter((v, i, a) => a.indexOf(v) === i);

          return this.fetchAllowedValueQuery(query);
        });
    } else {
      return this.fetchAllowedValueQuery(query);
    }
  }

  protected allowedValuesFilter(query?:string):{} {
    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

    if ((this._autocompleterComponent as TimeEntryWorkPackageAutocompleterComponent).mode === 'recent') {
      filters.add('id', '=', this.recentWorkPackageIds);
    }

    if (query) {
      filters.add('subjectOrId', '**', [query]);
    }

    return { filters: filters.toJson() };
  }

  protected sortValues(availableValues:HalResource[]) {
    if ((this._autocompleterComponent as TimeEntryWorkPackageAutocompleterComponent).mode === 'recent') {
      return this.sortValuesByRecentIds(availableValues);
    } else {
      return super.sortValues(availableValues);
    }
  }

  protected sortValuesByRecentIds(availableValues:HalResource[]) {
    return availableValues
      .sort((a, b) => {
        return this.recentWorkPackageIds.indexOf(a.id!) - this.recentWorkPackageIds.indexOf(b.id!);
      });
  }
}
