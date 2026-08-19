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

import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HighlightingMode } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting-mode.const';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';

export interface QueryResourceEmbedded {
  results:WorkPackageCollectionResource;
  columns:QueryColumn[];
  groupBy:QueryGroupByResource|undefined;
  project:ProjectResource;
  user:UserResource;
  sortBy:QuerySortByResource[];
  filters:QueryFilterInstanceResource[];
}

export type TimelineZoomLevel = 'days'|'weeks'|'months'|'quarters'|'years'|'auto';

export interface TimelineLabels {
  left:string|null;
  right:string|null;
  farRight:string|null;
}

export class QueryResource extends HalResource {
  public $embedded:QueryResourceEmbedded;

  public results:WorkPackageCollectionResource;

  public columns:QueryColumn[];

  public groupBy:QueryGroupByResource|undefined;

  public sortBy:QuerySortByResource[];

  public setSortBy(newSortBy:QuerySortByResource[]):void {
    this.sortBy = newSortBy;
  }

  public filters:QueryFilterInstanceResource[];

  public starred:boolean;

  public sums:boolean;

  public hasError:boolean;

  public timelineVisible:boolean;

  public timelineZoomLevel:TimelineZoomLevel;

  public highlightingMode:HighlightingMode;

  public highlightedAttributes:HalResource[]|undefined;

  public displayRepresentation:string|undefined;

  public timelineLabels:TimelineLabels;

  public timestamps:string[];

  public showHierarchies:boolean;

  public public:boolean;

  public hidden:boolean;

  public user:UserResource;

  public project:ProjectResource;

  public includeSubprojects:boolean;

  public ordered_work_packages:QueryOrder;

  public $initialize(source:any) {
    super.$initialize(source);

    this.filters = this
      .filters
      .map((filter:unknown) => new QueryFilterInstanceResource(
        this.injector,
        filter,
        true,
        this.halInitializer,
        'QueryFilterInstance',
      ));
  }
}

export interface QueryResourceLinks {
  updateImmediately?(attributes:any):Promise<any>;
  icalUrl(payload:unknown):Promise<{ icalUrl:{ href:string } }>;
}

export interface QueryResource extends QueryResourceLinks {}
