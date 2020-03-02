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
import {WorkPackageNewFullViewComponent} from 'core-components/wp-new/wp-new-full-view.component';
import {WorkPackageCopyFullViewComponent} from 'core-components/wp-copy/wp-copy-full-view.component';
import {WorkPackageNewSplitViewComponent} from 'core-components/wp-new/wp-new-split-view.component';
import {WorkPackageCopySplitViewComponent} from 'core-components/wp-copy/wp-copy-split-view.component';
import {WorkPackagesFullViewComponent} from "core-app/modules/work_packages/routing/wp-full-view/wp-full-view.component";
import {WorkPackageSplitViewComponent} from "core-app/modules/work_packages/routing/wp-split-view/wp-split-view.component";
import {Ng2StateDeclaration} from "@uirouter/angular";
import {WorkPackagesBaseComponent} from "core-app/modules/work_packages/routing/wp-base/wp--base.component";
import {WorkPackageListViewComponent} from "core-app/modules/work_packages/routing/wp-list-view/wp-list-view.component";
import {WorkPackageViewPageComponent} from "core-app/modules/work_packages/routing/wp-view-page/wp-view-page.component";
import {WorkPackageSingleViewComponent} from "core-components/work-packages/wp-single-view/wp-single-view.component";
import {ComponentType} from "@angular/cdk/overlay";

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
 * @param baseRoute The base route to mount under
 * @param component The split view component to mount
 */
export function makeSplitViewRoutes(baseRoute:string,
                                    menuItemClass:string|undefined,
                                    component:ComponentType<any>):Ng2StateDeclaration[] {
  return [
    {
      name: baseRoute + '.details',
      url: '/details/{workPackageId:[0-9]+}',
      redirectTo: baseRoute + '.details.overview',
      reloadOnSearch: false,
      data: {
        bodyClasses: 'router--work-packages-partitioned-split-view',
        menuItem: menuItemClass,
        partition: '-split'
      },
      views: {
        // Retarget and by that override the grandparent views
        // https://ui-router.github.io/guide/views#relative-parent-state
        'content-right@^.^': {component: component}
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
  ];
}
