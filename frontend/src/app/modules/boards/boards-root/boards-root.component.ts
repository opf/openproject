import { Component, Injector } from "@angular/core";
import { BoardConfigurationService } from "core-app/modules/boards/board/configuration-modal/board-configuration.service";
import { BoardActionsRegistryService } from "core-app/modules/boards/board/board-actions/board-actions-registry.service";
import { BoardStatusActionService } from "core-app/modules/boards/board/board-actions/status/status-action.service";
import { BoardVersionActionService } from "core-app/modules/boards/board/board-actions/version/version-action.service";
import { QueryUpdatedService } from "core-app/modules/boards/board/query-updated/query-updated.service";
import { BoardAssigneeActionService } from "core-app/modules/boards/board/board-actions/assignee/assignee-action.service";
import { BoardSubprojectActionService } from "core-app/modules/boards/board/board-actions/subproject/subproject-action.service";
import { BoardSubtasksActionService } from "core-app/modules/boards/board/board-actions/subtasks/board-subtasks-action.service";

@Component({
  selector: 'boards-entry',
  template: '<ui-view wp-isolated-query-space></ui-view>',
  providers: [
    BoardConfigurationService,
    BoardStatusActionService,
    BoardVersionActionService,
    BoardAssigneeActionService,
    BoardSubprojectActionService,
    BoardSubtasksActionService,
    QueryUpdatedService,
  ]
})
export class BoardsRootComponent {

  constructor(readonly injector:Injector) {

    // Register action services
    const registry = injector.get(BoardActionsRegistryService);

    registry.add('status', injector.get(BoardStatusActionService));
    registry.add('assignee', injector.get(BoardAssigneeActionService));
    registry.add('version', injector.get(BoardVersionActionService));
    registry.add('subproject', injector.get(BoardSubprojectActionService));
    registry.add('subtasks', injector.get(BoardSubtasksActionService));
  }
}
