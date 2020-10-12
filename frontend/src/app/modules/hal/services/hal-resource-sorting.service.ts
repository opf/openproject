//-- copyright
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
//++

import {Injectable} from '@angular/core';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';

@Injectable({ providedIn: 'root' })
export class HalResourceSortingService {

  /**
   * List of sortable properties by HAL type
   */
  private config:{ [typeName:string]:string } = {
    'user': 'name',
    'project': 'name'
  };

  constructor() {
  }

  /**
   * Sort the given HalResource based on its type.
   * If the type is not given, guess from the first element.
   *
   * @param {T[]} elements A collection of HalResources of type T
   * @param {string} type The HAL type of the collection
   * @returns {T[]} The sorted collection of HalResources
   */
  public sort<T extends HalResource>(elements:T[], type?:string) {
    if (elements.length === 0) {
      return elements;
    }

    const halType = type || elements[0]._type;
    if (!halType) {
      return elements;
    }

    const property = this.sortingProperty(halType);
    if (property) {
      return _.sortBy<T>(elements, v => v[property].toLowerCase());
    } else {
      return elements;
    }
  }

  /**
   * Transform the HAL type into the sorting property map.
   *
   *  - Removes the leading multi identifier [] (e.g., from []User)
   *  - Transforms to lowercase
   *
   * @param {string} type
   * @returns {string | undefined}
   */
  public sortingProperty(type:string):string | undefined {
    // Remove multi identifier and map to lowercase
    type = type
      .toLowerCase()
      .replace(/^\[\]/, '');

    return this.config[type];
  }

  public hasSortingProperty(type:string) {
    return this.sortingProperty(type) !== undefined;
  }

}
