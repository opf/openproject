// -- copyright
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { Ng2StateDeclaration } from '@uirouter/angular';
import { makeSplitViewRoutes } from 'core-app/features/work-packages/routing/split-view-routes.template';
import { WorkPackageSplitViewComponent } from 'core-app/features/work-packages/routing/wp-split-view/wp-split-view.component';
import { InAppNotificationCenterComponent } from 'core-app/features/in-app-notifications/center/in-app-notification-center.component';
import { InAppNotificationCenterPageComponent } from 'core-app/features/in-app-notifications/center/in-app-notification-center-page.component';
import { WorkPackagesBaseComponent } from 'core-app/features/work-packages/routing/wp-base/wp--base.component';
import { EmptyStateComponent } from './center/empty-state/empty-state.component';

export interface INotificationPageQueryParameters {
  filter?:string;
  name?:string;
}

export const IAN_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'notifications',
    parent: 'root',
    url: '/notifications?{filter:string}&{name:string}',
    data: {
      bodyClasses: 'router--work-packages-base',
    },
    redirectTo: 'notifications.center.show',
    views: {
      '!$default': { component: WorkPackagesBaseComponent },
    },
  },
  {
    name: 'notifications.center',
    component: InAppNotificationCenterPageComponent,
    redirectTo: 'notifications.center.show',
  },
  {
    name: 'notifications.center.show',
    data: {
      baseRoute: 'notifications.center.show',
    },
    views: {
      'content-left': { component: InAppNotificationCenterComponent },
      'content-right': { component: EmptyStateComponent },
    },
  },
  ...makeSplitViewRoutes(
    'notifications.center.show',
    undefined,
    WorkPackageSplitViewComponent,
  ),
];
