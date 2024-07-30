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
import { WorkPackagesCalendarComponent } from 'core-app/features/calendar/wp-calendar/wp-calendar.component';
import { WorkPackagesCalendarPageComponent } from 'core-app/features/calendar/wp-calendar-page/wp-calendar-page.component';

export const sidemenuId = 'calendar_sidemenu';
export const sideMenuOptions = {
  sidemenuId,
  hardReloadOnBaseRoute: true,
  defaultQuery: 'new',
};

export const CALENDAR_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'calendar',
    parent: 'optional_project',
    url: '/calendars/:query_id?&query_props&cdate&cview',
    redirectTo: 'calendar.page',
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
    name: 'calendar.page',
    component: WorkPackagesCalendarPageComponent,
    redirectTo: 'calendar.page.show',
    data: {
      bodyClasses: 'router--calendar',
      sideMenuOptions,
    },
  },
  {
    name: 'calendar.page.show',
    data: {
      baseRoute: 'calendar.page.show',
      sideMenuOptions,
    },
    views: {
      'content-left': { component: WorkPackagesCalendarComponent },
    },
  },
  ...makeSplitViewRoutes(
    'calendar.page.show',
    undefined,
    WorkPackageSplitViewComponent,
  ),
];
