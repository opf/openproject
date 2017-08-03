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

import {HalResource} from './hal-resource.service';
import {WorkPackageCollectionResourceInterface} from './wp-collection-resource.service';
import {QueryFilterInstanceResource} from './query-filter-instance-resource.service';
import {QuerySortByResource} from './query-sort-by-resource.service';
import {QueryGroupByResource} from './query-group-by-resource.service';
import {ProjectResource} from './project-resource.service';
import {opApiModule} from '../../../../angular-modules';
import {QueryColumn} from '../../../wp-query/query-column';

interface QueryResourceEmbedded {
  results:WorkPackageCollectionResourceInterface;
  columns:QueryColumn[];
  groupBy:QueryGroupByResource | undefined;
  project:ProjectResource;
  sortBy:QuerySortByResource[];
  filters:QueryFilterInstanceResource[];
}

export type TimelineZoomLevel = 'days' | 'weeks' | 'months' | 'quarters' | 'years';

export class QueryResource extends HalResource {
  public $embedded:QueryResourceEmbedded;
  public id:number;
  public results:WorkPackageCollectionResourceInterface;
  public columns:QueryColumn[];
  public groupBy:QueryGroupByResource | undefined;
  public sortBy:QuerySortByResource[];
  public filters:QueryFilterInstanceResource[];
  public starred:boolean;
  public sums:boolean;
  public timelineVisible:boolean;
  public timelineZoomLevel:TimelineZoomLevel;
  public showHierarchies:boolean;
  public public:boolean;
  public project:ProjectResource;

  public $initialize(source:any) {
    super.$initialize(source);

    this.filters = source.filters.map((filter:Object) => new QueryFilterInstanceResource(filter));
  }
}

function queryResource() {
  return QueryResource;
}

export interface QueryResourceInterface extends QueryResourceEmbedded, QueryResource {
}


opApiModule.factory('QueryResource', queryResource);
