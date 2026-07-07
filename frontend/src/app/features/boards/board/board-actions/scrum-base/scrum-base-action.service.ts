import { Injectable } from '@angular/core';
import { BoardStatusActionService } from 'core-app/features/boards/board/board-actions/status/status-action.service';

// Scrum Base board action service.
//
// Phase 0: a Scrum Base board's columns are workflow statuses and dragging a card
// changes its status, so this reuses the entire Status action behaviour
// (filterName/resourceName = 'status', the status header, the add-list modal).
// It exists as its own service registered under the 'scrum_base' attribute so the
// later phases (multi-status columns, swimlanes, WIP limits) can override
// behaviour here without touching the plain Status board.
@Injectable()
export class BoardScrumBaseActionService extends BoardStatusActionService {
  // Label shown in the "add list" modal / board chrome. The board tile title
  // and description come from the backend (boards.board_type_attributes.scrum_base).
  text = 'Scrum Base';
}
