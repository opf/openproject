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

import {WorkPackageOverviewTabComponent} from 'core-components/wp-single-view-tabs/overview-tab/overview-tab.component';
import {WorkPackageActivityTabComponent} from 'core-components/wp-single-view-tabs/activity-panel/activity-tab.component';
import {WorkPackageRelationsTabComponent} from 'core-components/wp-single-view-tabs/relations-tab/relations-tab.component';
import {WorkPackageWatchersTabComponent} from 'core-components/wp-single-view-tabs/watchers-tab/watchers-tab.component';
import {WorkPackageNewSplitViewComponent} from 'core-components/wp-new/wp-new-split-view.component';
import {Ng2StateDeclaration} from "@uirouter/angular";
import {ComponentType} from "@angular/cdk/overlay";
import {WorkPackageCopySplitViewComponent} from "core-components/wp-copy/wp-copy-split-view.component";

/**
 * Return a set of routes for a split view mounted under the given base route,
 * which must be a grandchild of a PartitionedQuerySpacePageComponent.
 *
 * Example: base route = foo.bar
 *
 * Split view will be created at
 *
 * foo.bar.details
 * foo.bar.details.activity
 * foo.bar.details.relations
 * foo.bar.details.watchers
 *
 * NOTE: All parameters here must either be `export const` or literal strings,
 * otherwise AOT will not be able to look them up. This might result in missing routes.
 *
 * @param baseRoute The base route to mount under
 * @param showComponent The split view component to mount
 */
export function makeSplitViewRoutes(baseRoute:string,
                                    menuItemClass:string|undefined,
                                    showComponent:ComponentType<any>,
                                    newComponent:ComponentType<any> = WorkPackageNewSplitViewComponent):Ng2StateDeclaration[] {
  return [
    {
      name: baseRoute + '.details',
      url: '/details/{workPackageId:[0-9]+}',
      redirectTo: baseRoute + '.details.overview',
      reloadOnSearch: false,
      data: {
        bodyClasses: 'router--work-packages-partitioned-split-view-details',
        menuItem: menuItemClass,
        // Remember the base route so we can route back to it anywhere
        baseRoute: baseRoute,
        partition: '-split',
        newRoute: baseRoute + '.new',
      },
      views: {
        // Retarget and by that override the grandparent views
        // https://ui-router.github.io/guide/views#relative-parent-state
        'content-right@^.^': { component: showComponent }
      }
    },
    {
      name: baseRoute + '.details.overview',
      url: '/overview',
      component: WorkPackageOverviewTabComponent,
      data: {
        menuItem: menuItemClass,
        parent: baseRoute + '.details'
      }
    },
    {
      name: baseRoute + '.details.activity',
      url: '/activity',
      component: WorkPackageActivityTabComponent,
      data: {
        menuItem: menuItemClass,
        parent: baseRoute + '.details'
      }
    },
    {
      name: baseRoute + '.details.relations',
      url: '/relations',
      component: WorkPackageRelationsTabComponent,
      data: {
        menuItem: menuItemClass,
        parent: baseRoute + '.details'
      }
    },
    {
      name: baseRoute + '.details.watchers',
      url: '/watchers',
      component: WorkPackageWatchersTabComponent,
      data: {
        menuItem: menuItemClass,
        parent: baseRoute + '.details'
      }
    },
    // Split create route
    {
      name: baseRoute + '.new',
      url: '/create_new?{type:[0-9]+}&{parent_id:[0-9]+}',
      reloadOnSearch: false,
      data: {
        partition: '-split',
        allowMovingInEditMode: true,
        bodyClasses: 'router--work-packages-partitioned-split-view-new',
        // Remember the base route so we can route back to it anywhere
        baseRoute: baseRoute,
        parent: baseRoute
      },
      views: {
        // Retarget and by that override the grandparent views
        // https://ui-router.github.io/guide/views#relative-parent-state
        'content-right@^.^': { component: newComponent }
      }
    },
    // Split copy route
    {
      name: baseRoute + '.copy',
      url: '/details/{copiedFromWorkPackageId:[0-9]+}/copy',
      views: {
        'content-right@^.^': { component: WorkPackageCopySplitViewComponent }
      },
      reloadOnSearch: false,
      data: {
        baseRoute: baseRoute,
        parent: baseRoute,
        allowMovingInEditMode: true,
        bodyClasses: 'router--work-packages-partitioned-split-view',
        menuItem: menuItemClass,
        partition: '-split'
      },
    },
  ];
}
