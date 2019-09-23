// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

import {APP_INITIALIZER, Injector, NgModule} from '@angular/core';
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";
import {OpenprojectWorkPackagesModule} from "core-app/modules/work_packages/openproject-work-packages.module";
import {Ng2StateDeclaration, UIRouter, UIRouterModule} from "@uirouter/angular";
import {BoardComponent} from "core-app/modules/boards/board/board.component";
import {BoardListComponent} from "core-app/modules/boards/board/board-list/board-list.component";
import {BoardsRootComponent} from "core-app/modules/boards/boards-root/boards-root.component";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {BoardInlineAddAutocompleterComponent} from "core-app/modules/boards/board/inline-add/board-inline-add-autocompleter.component";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {BoardsToolbarMenuDirective} from "core-app/modules/boards/board/toolbar-menu/boards-toolbar-menu.directive";
import {BoardConfigurationService} from "core-app/modules/boards/board/configuration-modal/board-configuration.service";
import {BoardConfigurationModal} from "core-app/modules/boards/board/configuration-modal/board-configuration.modal";
import {BoardsIndexPageComponent} from "core-app/modules/boards/index-page/boards-index-page.component";
import {BoardsMenuComponent} from "core-app/modules/boards/boards-sidebar/boards-menu.component";
import {BoardDmService} from "core-app/modules/boards/board/board-dm.service";
import {NewBoardModalComponent} from "core-app/modules/boards/new-board-modal/new-board-modal.component";
import {BoardActionsRegistryService} from "core-app/modules/boards/board/board-actions/board-actions-registry.service";
import {AddListModalComponent} from "core-app/modules/boards/board/add-list-modal/add-list-modal.component";
import {BoardHighlightingTabComponent} from "core-app/modules/boards/board/configuration-modal/tabs/highlighting-tab.component";
import {AddCardDropdownMenuDirective} from "core-app/modules/boards/board/add-card-dropdown/add-card-dropdown-menu.directive";
import {BoardFilterComponent} from "core-app/modules/boards/board/board-filter/board-filter.component";
import {DragScrollModule} from "cdk-drag-scroll";
import {BoardListMenuComponent} from "core-app/modules/boards/board/board-list/board-list-menu.component";
import {VersionBoardHeaderComponent} from "core-app/modules/boards/board/board-actions/version/version-board-header.component";
import {DynamicModule} from "ng-dynamic-component";
import {BoardStatusActionService} from "core-app/modules/boards/board/board-actions/status/status-action.service";
import {BoardVersionActionService} from "core-app/modules/boards/board/board-actions/version/version-action.service";
import {QueryUpdatedService} from "core-app/modules/boards/board/query-updated/query-updated.service";

const menuItemClass = 'board-view-menu-item';

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
    name: 'boards.show',
    url: '{board_id}',
    params: {
      board_id: {type: 'int'},
      isNew: {type: 'bool', inherit: false, dynamic: true}
    },
    reloadOnSearch: false,
    component: BoardComponent,
    data: {
      parent: 'boards',
      bodyClasses: 'router--boards-full-view',
      menuItem: menuItemClass
    }
  }
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

export function registerBoardsModule(injector:Injector) {
  return () => {
    // Register action services
    const registry = injector.get(BoardActionsRegistryService);
    const statusAction = injector.get(BoardStatusActionService);
    const versionAction = injector.get(BoardVersionActionService);

    registry.add('status', statusAction);
    registry.add('version', versionAction);
  };
}

@NgModule({
  imports: [
    OpenprojectCommonModule,
    OpenprojectWorkPackagesModule,
    DragScrollModule,

    // Dynamic Module for actions
    DynamicModule.withComponents([VersionBoardHeaderComponent]),

    // Routes for /boards
    UIRouterModule.forChild({
      states: BOARDS_ROUTES,
      config: uiRouterBoardsConfiguration
    }),
  ],
  providers: [
    BoardService,
    BoardDmService,
    BoardListsService,
    BoardCacheService,
    BoardConfigurationService,
    BoardActionsRegistryService,
    BoardStatusActionService,
    BoardVersionActionService,
    QueryUpdatedService,
    {
      provide: APP_INITIALIZER,
      useFactory: registerBoardsModule,
      deps: [Injector],
      multi: true
    },
  ],
  declarations: [
    BoardsIndexPageComponent,
    BoardComponent,
    BoardListComponent,
    BoardsRootComponent,
    BoardInlineAddAutocompleterComponent,
    BoardsMenuComponent,
    BoardHighlightingTabComponent,
    BoardConfigurationModal,
    BoardsToolbarMenuDirective,
    NewBoardModalComponent,
    AddListModalComponent,
    AddCardDropdownMenuDirective,
    BoardListMenuComponent,
    BoardFilterComponent,
    VersionBoardHeaderComponent,
  ],
  entryComponents: [
    BoardInlineAddAutocompleterComponent,
    BoardsMenuComponent,
    BoardConfigurationModal,
    BoardHighlightingTabComponent,
    NewBoardModalComponent,
    AddListModalComponent,
    VersionBoardHeaderComponent,
  ]
})
export class OpenprojectBoardsModule {
}

