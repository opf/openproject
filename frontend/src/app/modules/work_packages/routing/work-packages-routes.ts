//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { WorkPackageActivityTabComponent } from 'core-components/wp-single-view-tabs/activity-panel/activity-tab.component';
import { WorkPackageRelationsTabComponent } from 'core-components/wp-single-view-tabs/relations-tab/relations-tab.component';
import { WorkPackageWatchersTabComponent } from 'core-components/wp-single-view-tabs/watchers-tab/watchers-tab.component';
import { WorkPackageNewFullViewComponent } from 'core-components/wp-new/wp-new-full-view.component';
import { WorkPackageCopyFullViewComponent } from 'core-components/wp-copy/wp-copy-full-view.component';
import { WorkPackagesFullViewComponent } from "core-app/modules/work_packages/routing/wp-full-view/wp-full-view.component";
import { WorkPackageSplitViewComponent } from "core-app/modules/work_packages/routing/wp-split-view/wp-split-view.component";
import { Ng2StateDeclaration } from "@uirouter/angular";
import { WorkPackagesBaseComponent } from "core-app/modules/work_packages/routing/wp-base/wp--base.component";
import { WorkPackageListViewComponent } from "core-app/modules/work_packages/routing/wp-list-view/wp-list-view.component";
import { WorkPackageViewPageComponent } from "core-app/modules/work_packages/routing/wp-view-page/wp-view-page.component";
import { makeSplitViewRoutes } from "core-app/modules/work_packages/routing/split-view-routes.template";

export const menuItemClass = 'work-packages-menu-item';

export const WORK_PACKAGES_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'work-packages',
    parent: 'root',
    component: WorkPackagesBaseComponent,
    url: '/work_packages?query_id&query_props&start_onboarding_tour',
    redirectTo: 'work-packages.partitioned.list',
    data: {
      bodyClasses: 'router--work-packages-base',
      menuItem: menuItemClass
    },
    params: {
      query_id: { type: 'query', dynamic: true },
      // Use custom encoder/decoder that ensures validity of URL string
      query_props: { type: 'opQueryString' },
      // Optional initial tour param
      start_onboarding_tour: { type: 'query', squash: true, value: undefined },
    }
  },
  {
    name: 'work-packages.new',
    url: '/new?type&parent_id',
    component: WorkPackageNewFullViewComponent,
    reloadOnSearch: false,
    data: {
      baseRoute: 'work-packages',
      allowMovingInEditMode: true,
      bodyClasses: 'router--work-packages-full-create',
      menuItem: menuItemClass
    },
  },
  {
    name: 'work-packages.copy',
    url: '/{copiedFromWorkPackageId:[0-9]+}/copy',
    component: WorkPackageCopyFullViewComponent,
    reloadOnSearch: false,
    data: {
      baseRoute: 'work-packages',
      allowMovingInEditMode: true,
      bodyClasses: 'router--work-packages-full-create',
      menuItem: menuItemClass
    },
  },
  {
    name: 'work-packages.show',
    url: '/{workPackageId:[0-9]+}',
    // Redirect to 'activity' by default.
    redirectTo: 'work-packages.show.activity',
    component: WorkPackagesFullViewComponent,
    data: {
      baseRoute: 'work-packages',
      bodyClasses: 'router--work-packages-full-view',
      newRoute: 'work-packages.new',
      menuItem: menuItemClass
    }
  },
  {
    name: 'work-packages.show.activity',
    url: '/activity',
    component: WorkPackageActivityTabComponent,
    data: {
      parent: 'work-packages.show',
      menuItem: menuItemClass
    }
  },
  {
    name: 'work-packages.show.activity.details',
    url: '/activity/details/#{activity_no:\d+}',
    component: WorkPackageActivityTabComponent,
    data: {
      parent: 'work-packages.show',
      menuItem: menuItemClass
    }
  },
  {
    name: 'work-packages.show.relations',
    url: '/relations',
    component: WorkPackageRelationsTabComponent,
    data: {
      parent: 'work-packages.show',
      menuItem: menuItemClass
    }
  },
  {
    name: 'work-packages.show.watchers',
    url: '/watchers',
    component: WorkPackageWatchersTabComponent,
    data: {
      parent: 'work-packages.show',
      menuItem: menuItemClass
    }
  },
  {
    name: 'work-packages.partitioned',
    component: WorkPackageViewPageComponent,
    url: '',
    data: {
      // This has to be empty to avoid inheriting the parent bodyClasses
      bodyClasses: ''
    }
  },
  {
    name: 'work-packages.partitioned.list',
    url: '',
    reloadOnSearch: false,
    views: {
      'content-left': { component: WorkPackageListViewComponent }
    },
    data: {
      bodyClasses: 'router--work-packages-partitioned-split-view',
      menuItem: menuItemClass,
      partition: '-left-only'
    }
  },
  ...makeSplitViewRoutes(
    'work-packages.partitioned.list',
    menuItemClass,
    WorkPackageSplitViewComponent
  )
  // Avoid lazy-loading the routes for now
  // {
  //   name: 'work-packages.calendar.**',
  //   url: '/calendar',
  //   loadChildren: '../calendar/openproject-calendar.module#OpenprojectCalendarModule'
  // },
];
