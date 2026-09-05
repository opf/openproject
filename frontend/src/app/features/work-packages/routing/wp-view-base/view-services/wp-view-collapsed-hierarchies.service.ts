// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2024 the OpenProject GmbH
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

import { Injectable } from '@angular/core';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { QuerySchemaResource } from 'core-app/features/hal/resources/query-schema-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageViewBaseService } from './wp-view-base.service';
import { tableRowClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/rows/single-row-builder';

@Injectable()
export class WorkPackageViewCollapsedHierarchiesService extends WorkPackageViewBaseService<IHierarchiesCollapseEvent> {
  constructor(
    protected readonly querySpace:IsolatedQuerySpace,
    readonly workPackageViewHierarchiesService:WorkPackageViewHierarchiesService,
  ) {
    super(querySpace);
  }

  get allHierarchiesAreCollapsed():boolean {
    return jQuery('.wp-table--hierarchy-indicator').toArray().every((element) => {
      return jQuery(element).hasClass('-hierarchy-collapsed');
    });
  }

  get allHierarchiesAreExpanded():boolean {
    return jQuery('.wp-table--hierarchy-indicator').toArray().every((element) => {
      return !jQuery(element).hasClass('-hierarchy-collapsed');
    });
  }

  setAllHierarchiesCollapseStateTo(collapsedState:boolean):void {
    const newState = {
      allHierarchiesChanged: true,
    };

    this.update(newState);

    // Find all hierarchy indicators and toggle their state
    const hierarchyIndicators = jQuery('.wp-table--hierarchy-indicator');
    hierarchyIndicators.each((index, element) => {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      const wpId:string = jQuery(element).closest(`.${tableRowClassName}`).data('workPackageId');

      if (collapsedState) {
        this.workPackageViewHierarchiesService.collapse(wpId);
      } else {
        this.workPackageViewHierarchiesService.expand(wpId);
      }
    });
  }

  initialize(_query:QueryResource, _results:WorkPackageCollectionResource, _schema?:QuerySchemaResource) {
  }

  valueFromQuery(_query:QueryResource, _results:WorkPackageCollectionResource) {
    return undefined;
  }

  applyToQuery(_query:QueryResource) {

  }
}
