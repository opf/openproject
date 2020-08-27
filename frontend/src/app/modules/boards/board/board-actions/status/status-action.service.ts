import {Injectable} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {StatusResource} from "core-app/modules/hal/resources/status-resource";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";
import {CachedBoardActionService} from "core-app/modules/boards/board/board-actions/cached-board-action.service";

@Injectable()
export class BoardStatusActionService extends CachedBoardActionService {
  filterName = 'status';

  text = this.I18n.t('js.boards.board_type.action_by_attribute',
  { attribute: this.I18n.t('js.boards.board_type.action_type.status')});

  description = this.I18n.t('js.boards.board_type.action_text',
  { attribute: this.I18n.t('js.boards.board_type.action_type.status')});

  label = this.I18n.t('js.boards.add_list_modal.labels.status');

  icon = 'icon-workflow';

  public get localizedName() {
    return this.I18n.t('js.work_packages.properties.status');
  }

  public addInitialColumnsForAction(board:Board):Promise<Board> {
    return this
      .loadValues()
      .toPromise()
      .then((results) =>
        Promise.all<unknown>(
          results.map((status:StatusResource) => {

            if (status.isDefault) {
              return this.addColumnWithActionAttribute(board, status);
            }

            return Promise.resolve(board);
          })
        )
          .then(() => board)
      );
  }

  public warningTextWhenNoOptionsAvailable() {
    return Promise.resolve(this.I18n.t('js.boards.add_list_modal.warning.status'));
  }

  protected loadUncached():Promise<StatusResource[]> {
    return this
      .apiV3Service
      .statuses
      .get()
      .toPromise()
      .then(collection => collection.elements);
  }
}
