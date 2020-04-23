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

export type FilterOperator = '='|'!*'|'!'|'~'|'o'|'>t-'|'<>d'|'**'|'ow' ;

export interface ApiV3FilterValue {
  operator:FilterOperator;
  values:any;
}

export interface ApiV3Filter {
  [filter:string]:ApiV3FilterValue;
}

export type ApiV3FilterObject = { [filter:string]:ApiV3FilterValue };

export class ApiV3FilterBuilder {

  private filterMap:ApiV3FilterObject = {};

  public add(name:string, operator:FilterOperator, values:any):this {
    this.filterMap[name] = {
      operator: operator,
      values: values
    };

    return this;
  }

  /**
   * Remove from the filter set
   * @param name
   */
  public remove(name:string) {
    delete this.filterMap[name];
  }

  /**
   * Turns the array-map style of query filters to an actual object
   *
   * @param filters APIv3 filter array [ {foo: { operator: '=', val: ['bar'] } }, ...]
   * @return A map { foo: { operator: '=', val: ['bar'] } , ... }
   */
  public toFilterObject(filters:ApiV3Filter[]):ApiV3FilterObject {
    let map:ApiV3FilterObject = {};

    filters.forEach((item:ApiV3Filter) => {
      _.each(item, (val:ApiV3FilterValue, filter:string) => {
        map[filter] = val;
      });
    });

    return map;
  }

  /**
   * Merges the other filters into the current set,
   * replacing them if the are duplicated.
   *
   * @param filters
   * @param only Only apply the given filters
   */
  public merge(filters:ApiV3Filter[], ...only:string[]) {
    const toAdd:ApiV3FilterObject = _.pickBy(
      this.toFilterObject(filters),
      (_, filter:string) => only.includes(filter)
    );

    this.filterMap = {
      ...this.filterMap,
      ...toAdd
    };
  }

  public get filters():ApiV3Filter[] {
    let filters:ApiV3Filter[] = [];
    _.each(this.filterMap, (val:ApiV3FilterValue, filter:string) => {
      filters.push({ [filter]: val });
    });

    return filters;
  }

  public toJson():string {
    return JSON.stringify(this.filters);
  }

  public toParams(mergeParams:{ [key:string]:string } = {}):string {
    let transformedFilters:string[] = [];

    transformedFilters = this.filters.map((filter:ApiV3Filter) => {
      return this.serializeFilter(filter);
    });

    let params = { filters: `[${transformedFilters.join(",")}]`, ...mergeParams };
    return new URLSearchParams(params).toString();
  }

  public clone() {
    let newFilters = new ApiV3FilterBuilder();

    this.filters.forEach(filter => {
      Object.keys(filter).forEach(name => {
        newFilters.add(name, filter[name].operator, filter[name].values);
      });
    });

    return newFilters;
  }

  private serializeFilter(filter:ApiV3Filter) {
    let transformedFilter:string;
    let keys:Array<string>;

    keys = Object.keys(filter);

    let typeName = keys[0];
    let operatorAndValues:any = filter[typeName];

    transformedFilter = `{"${typeName}":{"operator":"${operatorAndValues['operator']}","values":[${operatorAndValues['values']
      .map((val:any) => this.serializeFilterValue(val))
      .join(',')}]}}`;

    return transformedFilter;
  }

  private serializeFilterValue(filterValue:any) {
    return `"${filterValue}"`;
  }
}

export function buildApiV3Filter(name:string, operator:FilterOperator, values:any) {
  return new ApiV3FilterBuilder().add(name, operator, values);
}
