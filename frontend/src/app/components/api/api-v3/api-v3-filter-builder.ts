//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

export type FilterOperator = '=' | '!*' | '!' | '~' | 'o' | '>t-' | '**' ;

export interface ApiV3Filter {
  [filter:string]:{ operator:FilterOperator, values:any };
}

export class ApiV3FilterBuilder {

  public filters:ApiV3Filter[] = [];

  public add(name:string, operator:FilterOperator, values:any):this {
    let newFilter:ApiV3Filter = {};
    newFilter[name] = {
      operator: operator,
      values: values
    };

    this.filters.push(newFilter);
    return this;
  }

  public toJson():string {
    return JSON.stringify(this.filters);
  }

  public toParams():string {
    let transformedFilters:string[] = [];

    transformedFilters = this.filters.map((filter:ApiV3Filter) => {
      return this.serializeFilter(filter);
    });

    return `filters=${encodeURI(`[${transformedFilters.join(',')}]`)}`;
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
