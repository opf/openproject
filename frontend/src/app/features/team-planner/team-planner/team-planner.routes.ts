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

import { Ng2StateDeclaration } from '@uirouter/angular';
import { makeSplitViewRoutes } from 'core-app/features/work-packages/routing/split-view-routes.template';
import { WorkPackageSplitViewComponent } from 'core-app/features/work-packages/routing/wp-split-view/wp-split-view.component';
import { WorkPackagesBaseComponent } from 'core-app/features/work-packages/routing/wp-base/wp--base.component';
import { TeamPlannerPageComponent } from 'core-app/features/team-planner/team-planner/page/team-planner-page.component';
import { TeamPlannerComponent } from 'core-app/features/team-planner/team-planner/planner/team-planner.component';

export const sidemenuId = 'team_planner_sidemenu';
export const sideMenuOptions = {
  sidemenuId,
  hardReloadOnBaseRoute: true,
  defaultQuery: 'new',
};

export const TEAM_PLANNER_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'team_planner',
    parent: 'optional_project',
    url: '/team_planners/:query_id?query_props&cdate&cview',
    redirectTo: 'team_planner.page',
    views: {
      '!$default': { component: WorkPackagesBaseComponent },
    },
    params: {
      query_id: { type: 'opQueryId', dynamic: true },
      cdate: { type: 'string', dynamic: true },
      cview: { type: 'string', dynamic: true },
      // Use custom encoder/decoder that ensures validity of URL string
      query_props: { type: 'opQueryString' },
    },
  },
  {
    name: 'team_planner.page',
    component: TeamPlannerPageComponent,
    redirectTo: 'team_planner.page.show',
    data: {
      bodyClasses: 'router--team-planner',
      sideMenuOptions,
    },
  },
  {
    name: 'team_planner.page.show',
    data: {
      baseRoute: 'team_planner.page.show',
      sideMenuOptions,
    },
    views: {
      'content-left': { component: TeamPlannerComponent },
    },
  },
  ...makeSplitViewRoutes(
    'team_planner.page.show',
    undefined,
    WorkPackageSplitViewComponent,
  ),
];
