import {Component} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {BoardsService} from "core-app/modules/boards/board/boards.service";
import {Observable} from "rxjs";
import {StateService} from "@uirouter/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'boards-module',
  templateUrl: './boards-module.component.html',
  styleUrls: ['./boards-module.component.sass']
})
export class BoardsModuleComponent {

  public text = {
    create: this.I18n.t('js.relation_buttons.create_new')
  };

  public boards$:Observable<Board[]> = this.Boards.loadAll('foo');

  constructor(private readonly Boards:BoardsService,
              private readonly I18n:I18nService,
              private readonly state:StateService) {
  }

  newBoard() {
    this.Boards
      .create()
      .then((board) => {
        this.state.go('boards.show', { id: board.id });
      });
  }
}
