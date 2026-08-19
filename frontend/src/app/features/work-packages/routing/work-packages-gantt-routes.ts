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

import { WorkPackageSplitViewComponent } from 'core-app/features/work-packages/routing/wp-split-view/wp-split-view.component';
import { Ng2StateDeclaration } from '@uirouter/angular';
import { WorkPackagesBaseComponent } from 'core-app/features/work-packages/routing/wp-base/wp--base.component';
import { WorkPackageListViewComponent } from 'core-app/features/work-packages/routing/wp-list-view/wp-list-view.component';
import { WorkPackageViewPageComponent } from 'core-app/features/work-packages/routing/wp-view-page/wp-view-page.component';
import { makeSplitViewRoutes } from 'core-app/features/work-packages/routing/split-view-routes.template';

export const menuItemClass = 'gantt-menu-item';

export const sidemenuId = 'gantt_menu';
export const sideMenuOptions = {
  sidemenuId,
  hardReloadOnBaseRoute: true,
};

export const WORK_PACKAGES_GANTT_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'gantt',
    parent: 'optional_project',
    url: '/gantt?query_id&query_props&name&start_onboarding_tour',
    redirectTo: 'gantt.partitioned.list',
    views: {
      '!$default': { component: WorkPackagesBaseComponent },
    },
    data: {
      bodyClasses: 'router--work-packages-base',
      menuItem: menuItemClass,
      sideMenuOptions,
    },
    params: {
      query_id: { type: 'query', dynamic: true },
      // Use custom encoder/decoder that ensures validity of URL string
      query_props: { type: 'opQueryString' },
      // Optional initial tour param
      start_onboarding_tour: { type: 'query', squash: true, value: undefined },
      name: { type: 'string', dynamic: true },
    },
  },
  {
    name: 'gantt.partitioned',
    component: WorkPackageViewPageComponent,
    url: '',
    data: {
      // This has to be empty to avoid inheriting the parent bodyClasses
      bodyClasses: '',
      sideMenuOptions,
    },
  },
  {
    name: 'gantt.partitioned.list',
    url: '',
    reloadOnSearch: false,
    views: {
      'content-left': { component: WorkPackageListViewComponent },
    },
    data: {
      bodyClasses: 'router--work-packages-partitioned-split-view',
      menuItem: menuItemClass,
      partition: '-left-only',
      sideMenuOptions,
    },
  },
  ...makeSplitViewRoutes(
    'gantt.partitioned.list',
    menuItemClass,
    WorkPackageSplitViewComponent,
  ),
];
