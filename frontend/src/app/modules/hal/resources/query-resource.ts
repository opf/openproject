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

import {QueryColumn} from 'core-components/wp-query/query-column';
import {QueryGroupByResource} from 'core-app/modules/hal/resources/query-group-by-resource';
import {ProjectResource} from 'core-app/modules/hal/resources/project-resource';
import {QuerySortByResource} from 'core-app/modules/hal/resources/query-sort-by-resource';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {HighlightingMode} from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";

export interface QueryResourceEmbedded {
  results:WorkPackageCollectionResource;
  columns:QueryColumn[];
  groupBy:QueryGroupByResource|undefined;
  project:ProjectResource;
  sortBy:QuerySortByResource[];
  filters:QueryFilterInstanceResource[];
}

export type TimelineZoomLevel = 'days'|'weeks'|'months'|'quarters'|'years';

export interface TimelineLabels {
  left:string|null;
  right:string|null;
  farRight:string|null;
}

export class QueryResource extends HalResource {
  public $embedded:QueryResourceEmbedded;
  public id:number;
  public results:WorkPackageCollectionResource;
  public columns:QueryColumn[];
  public groupBy:QueryGroupByResource|undefined;
  public sortBy:QuerySortByResource[];
  public filters:QueryFilterInstanceResource[];
  public starred:boolean;
  public sums:boolean;
  public hasError:boolean;
  public timelineVisible:boolean;
  public timelineZoomLevel:TimelineZoomLevel;
  public highlightingMode:HighlightingMode;
  public timelineLabels:TimelineLabels;
  public showHierarchies:boolean;
  public public:boolean;
  public project:ProjectResource;

  public $initialize(source:any) {
    super.$initialize(source);

    this.filters = this
      .filters
      .map((filter:Object) => new QueryFilterInstanceResource(
          this.injector,
          filter,
          true,
          this.halInitializer,
          'QueryFilterInstance'
        )
      );
  }
}
