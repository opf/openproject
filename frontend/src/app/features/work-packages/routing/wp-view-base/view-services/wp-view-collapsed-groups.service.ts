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

import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Injectable } from '@angular/core';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { take } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { QuerySchemaResource } from 'core-app/features/hal/resources/query-schema-resource';
import { GroupObject, WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';
import { WorkPackageViewBaseService } from './wp-view-base.service';

@Injectable()
export class WorkPackageViewCollapsedGroupsService extends WorkPackageViewBaseService<IGroupsCollapseEvent> {
  readonly wpTypesToShowInCollapsedGroupHeaders:((wp:WorkPackageResource) => boolean)[];

  readonly groupTypesWithHeaderCellsWhenCollapsed = ['project'];

  get config():IGroupsCollapseEvent {
    return this.updatesState.getValueOr(this.getDefaultState());
  }

  get currentGroups():GroupObject[] {
    return this.querySpace.groups.value!;
  }

  get allGroupsAreCollapsed():boolean {
    return this.config.allGroupsAreCollapsed;
  }

  get allGroupsAreExpanded():boolean {
    return this.config.allGroupsAreExpanded;
  }

  get currentGroupedBy():QueryGroupByResource|null {
    return this.workPackageViewGroupByService.current;
  }

  constructor(
    protected readonly querySpace:IsolatedQuerySpace,
    readonly workPackageViewGroupByService:WorkPackageViewGroupByService,
    private schemaCacheService:SchemaCacheService,
  ) {
    super(querySpace);
    this.wpTypesToShowInCollapsedGroupHeaders = [this.isMilestone];
  }

  // Every time the groupedBy changes, this services is initialized
  private getDefaultState():IGroupsCollapseEvent {
    return {
      state: this.querySpace.collapsedGroups.value || {},
      allGroupsChanged: false,
      lastChangedGroup: null,
      groupedBy: this.currentGroupedBy?.id || null,
      ...this.getAllGroupsCollapsedState(this.currentGroups, this.querySpace.collapsedGroups.value!),
    };
  }

  isMilestone = (workPackage:WorkPackageResource):boolean => this.schemaCacheService.of(workPackage)?.isMilestone;

  toggleGroupCollapseState(groupIdentifier:string):void {
    const newCollapsedState = !this.config.state[groupIdentifier];
    const state = {
      ...this.config.state,
      [groupIdentifier]: newCollapsedState,
    };
    const newState = {
      ...this.config,
      state,
      lastChangedGroup: groupIdentifier,
      ...this.getAllGroupsCollapsedState(this.currentGroups, state),
    };

    this.update(newState);
  }

  setAllGroupsCollapseStateTo(collapsedState:boolean):void {
    const groupUpdatedState = this.currentGroups.reduce((updatedState:{ [key:string]:boolean }, group) => ({
      ...updatedState,
      [group.identifier]: collapsedState,
    }), {});
    const newState = {
      ...this.config,
      state: {
        ...this.config.state,
        ...groupUpdatedState,
      },
      lastChangedGroup: null,
      allGroupsAreCollapsed: collapsedState,
      allGroupsAreExpanded: !collapsedState,
      allGroupsChanged: true,
    };

    this.update(newState);
  }

  getAllGroupsCollapsedState(groups:GroupObject[], currentCollapsedGroupsState:IGroupsCollapseEvent['state']) {
    let allGroupsAreCollapsed = false;
    let allGroupsAreExpanded = true;

    if (currentCollapsedGroupsState && groups?.length) {
      const firstGroupIdentifier = groups[0].identifier;
      const firstGroupCollapsedState = currentCollapsedGroupsState[firstGroupIdentifier];
      const allGroupsHaveTheSameCollapseState = groups.every((group) => currentCollapsedGroupsState[group.identifier] != null
              && currentCollapsedGroupsState[group.identifier] === currentCollapsedGroupsState[firstGroupIdentifier]);

      allGroupsAreCollapsed = allGroupsHaveTheSameCollapseState && firstGroupCollapsedState;
      allGroupsAreExpanded = allGroupsHaveTheSameCollapseState && !firstGroupCollapsedState;
    }

    return { allGroupsAreCollapsed, allGroupsAreExpanded };
  }

  initialize(query:QueryResource, results:WorkPackageCollectionResource, schema?:QuerySchemaResource) {
    // When this service is initialized (first time the table is loaded and very time the groupBy changes),
    // we need to wait until the table is ready to emit the collapseStatus. Otherwise the groups are not
    // ready in the DOM and can't be collapsed/expanded.
    this.querySpace.tableRendered.values$().pipe(take(1)).subscribe(() => this.update({ ...this.config, allGroupsChanged: true }));
  }

  valueFromQuery(query:QueryResource, results:WorkPackageCollectionResource) {
    return this.getDefaultState();
  }

  applyToQuery(query:QueryResource) {

  }
}
