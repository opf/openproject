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

import { Ng2StateDeclaration, UIRouter } from "@uirouter/angular";
import { BoardsRootComponent } from "core-app/modules/boards/boards-root/boards-root.component";
import { BoardsIndexPageComponent } from "core-app/modules/boards/index-page/boards-index-page.component";
import { BoardPartitionedPageComponent } from "core-app/modules/boards/board/board-partitioned-page/board-partitioned-page.component";
import { BoardListContainerComponent } from "core-app/modules/boards/board/board-partitioned-page/board-list-container.component";
import { makeSplitViewRoutes } from "core-app/modules/work_packages/routing/split-view-routes.template";
import { WorkPackageSplitViewComponent } from "core-app/modules/work_packages/routing/wp-split-view/wp-split-view.component";

export const menuItemClass = 'board-view-menu-item';

export const BOARDS_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'boards',
    parent: 'root',
    // The trailing slash is important
    // cf., https://community.openproject.com/wp/29754
    url: '/boards/?query_props',
    data: {
      bodyClasses: 'router--boards-view-base',
      menuItem: menuItemClass
    },
    params: {
      // Use custom encoder/decoder that ensures validity of URL string
      query_props: { type: 'opQueryString', dynamic: true }
    },
    redirectTo: 'boards.list',
    component: BoardsRootComponent
  },
  {
    name: 'boards.list',
    component: BoardsIndexPageComponent,
    data: {
      parent: 'boards',
      bodyClasses: 'router--boards-list-view',
      menuItem: menuItemClass
    }
  },
  {
    name: 'boards.partitioned',
    url: '{board_id}',
    params: {
      board_id: { type: 'int' },
      isNew: { type: 'bool', inherit: false, dynamic: true }
    },
    data: {
      parent: 'boards',
      bodyClasses: 'router--boards-full-view',
      menuItem: menuItemClass
    },
    reloadOnSearch: false,
    component: BoardPartitionedPageComponent,
    redirectTo: 'boards.partitioned.show',
  },
  {
    name: 'boards.partitioned.show',
    url: '',
    data: {
      baseRoute: 'boards.partitioned.show'
    },
    views: {
      'content-left': { component: BoardListContainerComponent }
    }
  },
  ...makeSplitViewRoutes(
    'boards.partitioned.show',
    menuItemClass,
    WorkPackageSplitViewComponent
  )
];

export function uiRouterBoardsConfiguration(uiRouter:UIRouter) {
  // Ensure boards/ are being redirected correctly
  // cf., https://community.openproject.com/wp/29754
  uiRouter.urlService.rules
    .when(
      new RegExp("^/projects/(.*)/boards$"),
      match => `/projects/${match[1]}/boards/`
    );
}
