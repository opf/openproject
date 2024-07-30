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

import { Component } from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  DebouncedRequestSwitchmap,
  errorNotificationHandler,
} from 'core-app/shared/helpers/rxjs/debounced-input-switchmap';
import { take } from 'rxjs/operators';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { SelectEditFieldComponent } from './select-edit-field/select-edit-field.component';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';

@Component({
  templateUrl: './work-package-edit-field.component.html',
})
export class WorkPackageEditFieldComponent extends SelectEditFieldComponent {
  /** Keep a switchmap for search term and loading state */
  public requests = new DebouncedRequestSwitchmap<string, HalResource>(
    (searchTerm:string) => this.loadValues(searchTerm),
    errorNotificationHandler(this.halNotification),
  );

  protected initialValueLoading() {
    this.valuesLoaded = false;

    // Using this hack with the empty value to have the values loaded initially
    // while avoiding loading it multiple times.
    return new Promise<HalResource[]>((resolve) => {
      this.requests.output$.pipe(take(1)).subscribe((options) => {
        resolve(options);
      });

      this.requests.input$.next('');
    });
  }

  public get typeahead() {
    return this.requests.input$;
  }

  protected fetchAllowedValueQuery(query?:string):Promise<CollectionResource> {
    if (this.name === 'parent') {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call,@typescript-eslint/no-unsafe-member-access
      return this.schema.allowedValues.$link.$fetch({ query }) as Promise<CollectionResource>;
    }

    return super.fetchAllowedValueQuery(query);
  }

  protected allowedValuesFilter(query?:string):{} {
    let filterParams = super.allowedValuesFilter(query);

    if (query) {
      const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

      filters.add('subjectOrId', '**', [query]);

      filterParams = { filters: filters.toJson() };
    }

    return filterParams;
  }
}
