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
import {BoardsModuleComponent} from "core-app/modules/boards/boards-module.component";
import {initializeAvatarsPlugin} from "core-app/modules/plugins/linked/openproject-avatars/main";
import {HookService} from "core-app/modules/plugins/hook-service";
import {OpenprojectWorkPackagesModule} from "core-app/modules/work_packages/openproject-work-packages.module";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {Ng2StateDeclaration, UIRouterModule} from "@uirouter/angular";
import {WorkPackagesCalendarEntryComponent} from "core-app/modules/calendar/wp-calendar-entry/wp-calendar-entry.component";
import {BoardComponent} from "core-app/modules/boards/board/board.component";
import {BoardListComponent} from "core-app/modules/boards/board/board-list/board-list.component";
import {BoardsEntryComponent} from "core-app/modules/boards/boards-entry/boards-entry.component";
import {BoardsService} from "core-app/modules/boards/board/boards.service";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";

export const BOARDS_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'boards',
    parent: 'root',
    url: '/boards',
    redirectTo: 'boards.list',
    component: BoardsEntryComponent
  },
  {
    name: 'boards.list',
    component: BoardsModuleComponent
  },
  {
    name: 'boards.show',
    url: '/{id}',
    params: {
      id: { type: 'int' },
      board: { },
    },
    component: BoardComponent
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
    BoardsService,
    BoardListsService,
  ],
  declarations: [
    BoardsModuleComponent,
    BoardComponent,
    BoardListComponent,
    BoardsEntryComponent,
  ],
  entryComponents: [
  ]
})
export class OpenprojectBoardsModule { }

