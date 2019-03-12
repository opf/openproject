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

import {NgModule} from '@angular/core';
import {OpenprojectCommonModule} from "core-app/modules/common/openproject-common.module";
import {OpenprojectWorkPackagesModule} from "core-app/modules/work_packages/openproject-work-packages.module";
import {Ng2StateDeclaration, UIRouterModule} from "@uirouter/angular";
import {BoardComponent} from "core-app/modules/boards/board/board.component";
import {BoardListComponent} from "core-app/modules/boards/board/board-list/board-list.component";
import {BoardsRootComponent} from "core-app/modules/boards/boards-root/boards-root.component";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {BoardInlineAddAutocompleterComponent} from "core-app/modules/boards/board/inline-add/board-inline-add-autocompleter.component";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {BoardConfigurationDisplaySettingsTab} from "core-app/modules/boards/board/configuration-modal/tabs/display-settings-tab.component";
import {BoardsToolbarMenuDirective} from "core-app/modules/boards/board/toolbar-menu/boards-toolbar-menu.directive";
import {BoardConfigurationService} from "core-app/modules/boards/board/configuration-modal/board-configuration.service";
import {BoardConfigurationModal} from "core-app/modules/boards/board/configuration-modal/board-configuration.modal";
import {BoardsIndexPageComponent} from "core-app/modules/boards/index-page/boards-index-page.component";
import {BoardsMenuComponent} from "core-app/modules/boards/boards-sidebar/boards-menu.component";
import {BoardDmService} from "core-app/modules/boards/board/board-dm.service";

export const BOARDS_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'boards',
    parent: 'root',
    url: '/work_packages/boards',
    redirectTo: 'boards.list',
    component: BoardsRootComponent
  },
  {
    name: 'boards.list',
    component: BoardsIndexPageComponent,
    data: {
      parent: 'boards'
    }
  },
  {
    name: 'boards.show',
    url: '/{board_id}',
    params: {
      board_id: { type: 'int' },
      isNew: { type: 'bool' }
    },
    component: BoardComponent,
    data: {
      parent: 'boards'
    }
  }
];

@NgModule({
  imports: [
    OpenprojectCommonModule,
    OpenprojectWorkPackagesModule,

    // Routes for /boards
    UIRouterModule.forChild({ states: BOARDS_ROUTES }),
  ],
  providers: [
    BoardService,
    BoardDmService,
    BoardListsService,
    BoardCacheService,
    BoardConfigurationService,
  ],
  declarations: [
    BoardsIndexPageComponent,
    BoardComponent,
    BoardListComponent,
    BoardsRootComponent,
    BoardInlineAddAutocompleterComponent,
    BoardsMenuComponent,
    BoardConfigurationDisplaySettingsTab,
    BoardConfigurationModal,
    BoardsToolbarMenuDirective,
  ],
  entryComponents: [
    BoardInlineAddAutocompleterComponent,
    BoardsMenuComponent,
    BoardConfigurationModal,
    BoardConfigurationDisplaySettingsTab,
  ]
})
export class OpenprojectBoardsModule { }

