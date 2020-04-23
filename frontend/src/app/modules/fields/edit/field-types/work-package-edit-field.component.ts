// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {Component} from "@angular/core";
import {SelectEditFieldComponent, ValueOption} from './select-edit-field.component';
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {DebouncedRequestSwitchmap, errorNotificationHandler} from "core-app/helpers/rxjs/debounced-input-switchmap";
import { take } from 'rxjs/operators';

@Component({
  templateUrl: './work-package-edit-field.component.html'
})
export class WorkPackageEditFieldComponent extends SelectEditFieldComponent {
  /** Keep a switchmap for search term and loading state */
  public requests = new DebouncedRequestSwitchmap<string, ValueOption>(
    (searchTerm:string) => this.loadValues(searchTerm),
    errorNotificationHandler(this.halNotification)
  );

  protected initialValueLoading() {
    this.valuesLoaded = false;

    // Using this hack with the empty value to have the values loaded initially
    // while avoiding loading it multiple times.
    return new Promise<ValueOption[]>((resolve) => {
      this.requests.output$.pipe(take(1)).subscribe(options => {
        resolve(options);
      });

      this.requests.input$.next('');
    });
  }

  public get typeahead() {
    if (this.valuesLoaded) {
      return false;
    } else {
      return this.requests.input$;
    }
  }

  protected allowedValuesFilter(query?:string):{} {
    let filterParams = super.allowedValuesFilter(query);

    if (query) {
      let filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

      filters.add('subjectOrId', '**', [query]);

      filterParams = { filters: filters.toJson() };
    }

    return filterParams;
  }

  protected mapAllowedValue(value:WorkPackageResource|ValueOption):ValueOption {
    if ((value as WorkPackageResource).id) {

      let prefix = (value as WorkPackageResource).type ? `${(value as WorkPackageResource).type.name} ` : '';
      let suffix = (value as WorkPackageResource).subject || value.name;

      return {
        name: `${prefix}#${ (value as WorkPackageResource).id } ${suffix}`,
        $href: value.$href
      };
    } else {
      return value;
    }
  }
}
