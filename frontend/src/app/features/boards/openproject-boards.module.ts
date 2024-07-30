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

import { NgModule } from '@angular/core';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { UIRouterModule } from '@uirouter/angular';
import { BoardListComponent } from 'core-app/features/boards/board/board-list/board-list.component';
import { BoardsRootComponent } from 'core-app/features/boards/boards-root/boards-root.component';
import { BoardInlineAddAutocompleterComponent } from 'core-app/features/boards/board/inline-add/board-inline-add-autocompleter.component';
import { BoardsToolbarMenuDirective } from 'core-app/features/boards/board/toolbar-menu/boards-toolbar-menu.directive';
import { BoardConfigurationModalComponent } from 'core-app/features/boards/board/configuration-modal/board-configuration.modal';
import { AddListModalComponent } from 'core-app/features/boards/board/add-list-modal/add-list-modal.component';
import { BoardHighlightingTabComponent } from 'core-app/features/boards/board/configuration-modal/tabs/highlighting-tab.component';
import { AddCardDropdownMenuDirective } from 'core-app/features/boards/board/add-card-dropdown/add-card-dropdown-menu.directive';
import { BoardFilterComponent } from 'core-app/features/boards/board/board-filter/board-filter.component';
import { BoardListMenuComponent } from 'core-app/features/boards/board/board-list/board-list-menu.component';
import { VersionBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/version/version-board-header.component';
import { DynamicModule } from 'ng-dynamic-component';
import { BOARDS_ROUTES, uiRouterBoardsConfiguration } from 'core-app/features/boards/openproject-boards.routes';
import { BoardPartitionedPageComponent } from 'core-app/features/boards/board/board-partitioned-page/board-partitioned-page.component';
import { BoardListContainerComponent } from 'core-app/features/boards/board/board-partitioned-page/board-list-container.component';
import { BoardsMenuButtonComponent } from 'core-app/features/boards/board/toolbar-menu/boards-menu-button.component';
import { AssigneeBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/assignee/assignee-board-header.component';
import { SubprojectBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/subproject/subproject-board-header.component';
import { SubtasksBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/subtasks/subtasks-board-header.component';
import { StatusBoardHeaderComponent } from 'core-app/features/boards/board/board-actions/status/status-board-header.component';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';

@NgModule({
  imports: [
    OpSharedModule,
    OpenprojectWorkPackagesModule,
    OpenprojectModalModule,
    OpenprojectAutocompleterModule,

    // Dynamic Module for actions
    DynamicModule,

    // Routes for /boards
    UIRouterModule.forChild({
      states: BOARDS_ROUTES,
      config: uiRouterBoardsConfiguration,
    }),
  ],
  declarations: [
    BoardPartitionedPageComponent,
    BoardListContainerComponent,
    BoardListComponent,
    BoardsRootComponent,
    BoardInlineAddAutocompleterComponent,
    BoardHighlightingTabComponent,
    BoardConfigurationModalComponent,
    BoardsToolbarMenuDirective,
    BoardsMenuButtonComponent,
    AddListModalComponent,
    AddCardDropdownMenuDirective,
    BoardListMenuComponent,
    BoardFilterComponent,
    VersionBoardHeaderComponent,
    AssigneeBoardHeaderComponent,
    SubprojectBoardHeaderComponent,
    SubtasksBoardHeaderComponent,
    StatusBoardHeaderComponent,
  ],
})
export class OpenprojectBoardsModule {
}
