import {Component} from "@angular/core";
import {Observable} from "rxjs";
import {StateService} from "@uirouter/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {BoardService} from "core-app/modules/boards/board/board.service";
import {Board} from "core-app/modules/boards/board/board";
import {BoardCacheService} from "core-app/modules/boards/board/board-cache.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";

@Component({
  selector: 'boards-module',
  templateUrl: './boards-module.component.html'
})
export class BoardsModuleComponent {

  public text = {
    name: this.I18n.t('js.modals.label_name'),
    board: this.I18n.t('js.label_board'),
    boards: this.I18n.t('js.label_board_plural'),
    createdAt: this.I18n.t('js.label_created_on'),
    delete: this.I18n.t('js.button_delete'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
    deleteSuccessful: this.I18n.t('js.notice_successful_delete')
  };

  public boards$:Observable<Board[]> = this.BoardCache.observeAll();

  constructor(private readonly Boards:BoardService,
              private readonly BoardCache:BoardCacheService,
              private readonly I18n:I18nService,
              private readonly notifications:NotificationsService,
              private readonly state:StateService) {
    this.BoardCache.requireLoaded();
  }

  newBoard() {
    this.Boards
      .create()
      .then((board) => {
        this.state.go('boards.show', { id: board.id });
      });
  }

  destroyBoard(board:Board) {
    if (!window.confirm(this.text.areYouSure)) {
      return;
    }

    this.Boards
      .delete(board)
      .then(() => {
        this.BoardCache.clearSome(board.id);
        this.notifications.addSuccess(this.text.deleteSuccessful);
      })
      .catch((error) => this.notifications.addError("Deletion failed: " + error));
  }
}
