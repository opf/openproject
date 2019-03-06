// -- copyright
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
import {WorkPackagesListComponent} from "core-app/modules/work_packages/routing/wp-list/wp-list.component";
import {WorkPackageSplitViewComponent} from "core-app/modules/work_packages/routing/wp-split-view/wp-split-view.component";
import {Ng2StateDeclaration} from "@uirouter/angular";
import {WorkPackagesBaseComponent} from "core-app/modules/work_packages/routing/wp-base/wp--base.component";
import {MyPageComponent} from "core-components/routing/my-page/my-page.component";

export const WORK_PACKAGES_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'work-packages',
    parent: 'root',
    component: WorkPackagesBaseComponent,
    url: '/work_packages?query_id&query_props&start_onboarding_tour',
    redirectTo: 'work-packages.list',
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
      allowMovingInEditMode: true,
      bodyClasses: 'full-create'
    },
  },
  {
    name: 'work-packages.copy',
    url: '/{copiedFromWorkPackageId:[0-9]+}/copy',
    component: WorkPackageCopyFullViewComponent,
    reloadOnSearch: false,
    data: {
      allowMovingInEditMode: true,
      bodyClasses: 'full-create'
    },
  },
  {
    name: 'work-packages.show',
    url: '/{workPackageId:[0-9]+}',
    // Redirect to 'activity' by default.
    redirectTo: 'work-packages.show.activity',
    component: WorkPackagesFullViewComponent
  },
  {
    name: 'work-packages.show.activity',
    url: '/activity',
    component: WorkPackageActivityTabComponent,
    data: {
      parent: 'work-packages.show'
    }
  },
  {
    name: 'work-packages.show.activity.details',
    url: '/activity/details/#{activity_no:\d+}',
    component: WorkPackageActivityTabComponent,
    data: {
      parent: 'work-packages.show'
    }
  },
  {
    name: 'work-packages.show.relations',
    url: '/relations',
    component: WorkPackageRelationsTabComponent,
    data: {
      parent: 'work-packages.show'
    }
  },
  {
    name: 'work-packages.show.watchers',
    url: '/watchers',
    component: WorkPackageWatchersTabComponent,
    data: {
      parent: 'work-packages.show'
    }
  },
  {
    name: 'work-packages.list',
    url: '',
    component: WorkPackagesListComponent,
    reloadOnSearch: false,
    data: {
      bodyClasses: 'action-index'
    }
  },
  {
    name: 'work-packages.list.new',
    url: '/create_new?type&parent_id',
    component: WorkPackageNewSplitViewComponent,
    reloadOnSearch: false,
    data: {
      allowMovingInEditMode: true,
      bodyClasses: 'action-create',
      parent: 'work-packages.list'
    },
  },
  {
    name: 'work-packages.list.copy',
    url: '/details/{copiedFromWorkPackageId:[0-9]+}/copy',
    component: WorkPackageCopySplitViewComponent,
    reloadOnSearch: false,
    data: {
      allowMovingInEditMode: true,
      bodyClasses: 'action-details',
      parent: 'work-packages.list'
    },
  },
  {
    name: 'work-packages.list.details',
    redirectTo: 'work-packages.list.details.overview',
    url: '/details/{workPackageId:[0-9]+}',
    component: WorkPackageSplitViewComponent,
    reloadOnSearch: false,
    params: {
      focus: {
        dynamic: true,
        value: true
      }
    },
    data: {
      bodyClasses: 'action-details'
    },
  },
  {
    name: 'work-packages.list.details.overview',
    url: '/overview',
    component: WorkPackageOverviewTabComponent,
    data: {
      parent: 'work-packages.list.details'
    }
  },
  {
    name: 'work-packages.list.details.activity',
    url: '/activity',
    component: WorkPackageActivityTabComponent,
    data: {
      parent: 'work-packages.list.details'
    }
  },
  {
    name: 'work-packages.list.details.activity.details',
    url: '/activity/details/#{activity_no:\d+}',
    component: WorkPackageActivityTabComponent,
    data: {
      parent: 'work-packages.list.details'
    }
  },
  {
    name: 'work-packages.list.details.relations',
    url: '/relations',
    component: WorkPackageRelationsTabComponent,
    data: {
      parent: 'work-packages.list.details'
    }
  },
  {
    name: 'work-packages.list.details.watchers',
    url: '/watchers',
    component: WorkPackageWatchersTabComponent,
    data: {
      parent: 'work-packages.list.details'
    }
  },
  // Avoid lazy-loading the routes for now
  // {
  //   name: 'work-packages.calendar.**',
  //   url: '/calendar',
  //   loadChildren: '../calendar/openproject-calendar.module#OpenprojectCalendarModule'
  // },
];
