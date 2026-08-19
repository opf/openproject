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

import { ChangeDetectionStrategy, Component, ElementRef, Injector, Input, OnDestroy, inject } from '@angular/core';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';
import { BoardConfigurationService } from 'core-app/features/boards/board/configuration-modal/board-configuration.service';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { BoardStatusActionService } from 'core-app/features/boards/board/board-actions/status/status-action.service';
import { BoardVersionActionService } from 'core-app/features/boards/board/board-actions/version/version-action.service';
import { BoardAssigneeActionService } from 'core-app/features/boards/board/board-actions/assignee/assignee-action.service';
import { BoardSubprojectActionService } from 'core-app/features/boards/board/board-actions/subproject/subproject-action.service';
import { BoardSubtasksActionService } from 'core-app/features/boards/board/board-actions/subtasks/board-subtasks-action.service';
import { QueryUpdatedService } from 'core-app/features/boards/board/query-updated/query-updated.service';

@Component({
  selector: 'board-entry',
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  template: '<board-partitioned-page [boardId]="boardId"><board-list-container [boardId]="boardId" /></board-partitioned-page>',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    BoardConfigurationService,
    BoardStatusActionService,
    BoardVersionActionService,
    BoardAssigneeActionService,
    BoardSubprojectActionService,
    BoardSubtasksActionService,
    QueryUpdatedService,
  ],
  standalone: false,
})
export class BoardEntryComponent implements OnDestroy {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);
  readonly injector = inject(Injector);

  @Input() boardId:string;

  constructor() {
    const injector = this.injector;

    populateInputsFromDataset(this);

    document.body.classList.add('router--boards-full-view');

    const registry = injector.get(BoardActionsRegistryService);
    registry.add('status', injector.get(BoardStatusActionService));
    registry.add('assignee', injector.get(BoardAssigneeActionService));
    registry.add('version', injector.get(BoardVersionActionService));
    registry.add('subproject', injector.get(BoardSubprojectActionService));
    registry.add('subtasks', injector.get(BoardSubtasksActionService));
  }

  ngOnDestroy() {
    document.body.classList.remove('router--boards-full-view');
  }
}
