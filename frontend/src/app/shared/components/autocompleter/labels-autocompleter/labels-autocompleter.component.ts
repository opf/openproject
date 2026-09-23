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

import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { keyBy } from 'lodash-es';
import { BehaviorSubject, Observable } from 'rxjs';
import { map, tap } from 'rxjs/operators';
import {
  OpAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { addFiltersToPath } from 'core-app/core/apiv3/helpers/add-filters-to-path';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { compareByAttribute } from 'core-app/shared/helpers/angular/tracking-functions';
import {
  LabelsAutocompleterTemplateComponent,
} from 'core-app/shared/components/autocompleter/labels-autocompleter/labels-autocompleter-template.component';

export const labelsAutocompleterSelector = 'op-labels-autocompleter';

export interface ILabelAutocompleteItem {
  id:string|number;
  name:string;
  href:string|null;
}

export interface IApiLabel {
  id:string|number;
  name:string;
  _links:{ self:{ href:string|null } };
}

@Component({
  templateUrl: '../op-autocompleter/op-autocompleter.component.html',
  selector: labelsAutocompleterSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class LabelsAutocompleterComponent extends OpAutocompleterComponent<ILabelAutocompleteItem> implements OnInit {
  getOptionsFn = this.getLabels.bind(this);

  // Latest options from the server; results$ is cold and re-runs the request per subscriber.
  public readonly loadedLabels$ = new BehaviorSubject<ILabelAutocompleteItem[]>([]);

  ngOnInit():void {
    super.ngOnInit();
    this.applyTemplates(LabelsAutocompleterTemplateComponent);
  }

  public getLabels(searchTerm?:string):Observable<ILabelAutocompleteItem[]> {
    const filterObject = keyBy(this.filters, 'name');
    const filters = ApiV3FilterBuilder.fromFilterObject(filterObject);
    if (searchTerm?.length) {
      filters.add('name', '~', [searchTerm]);
    }

    const filteredURL = addFiltersToPath(this.url, filters);
    filteredURL.searchParams.set('pageSize', '-1');
    filteredURL.searchParams.set('select', 'elements/id,elements/name,elements/self,total,count,pageSize');

    return this
      .http
      .get<IHALCollection<IApiLabel>>(filteredURL.toString())
      .pipe(
        map((res) => res._embedded.elements.map((label) => ({ id: label.id, name: label.name, href: label._links.self.href }))),
        tap((labels) => this.loadedLabels$.next(labels)),
      );
  }

  protected defaultCompareWithFunction():(a:unknown, b:unknown) => boolean {
    return compareByAttribute('href', 'name');
  }

  protected defaultTrackByFunction():(item:{ href:unknown, name:unknown }) => unknown {
    return (item) => item.href ?? item.name;
  }
}
