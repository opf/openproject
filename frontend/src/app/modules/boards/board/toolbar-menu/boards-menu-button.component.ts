import {Component, Input} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {Board} from "core-app/modules/boards/board/board";
import {Observable} from "rxjs";

@Component({
  template: `
    <button title="{{ text.button_more }}"
            class="button last board--settings-dropdown toolbar-icon"
            boardsToolbarMenu
            [boardsToolbarMenu-resource]="board$ | async">
      <op-icon icon-classes="button--icon icon-show-more"></op-icon>
    </button>
  `
})
export class BoardsMenuButtonComponent {
  @Input() board$:Observable<Board>;

  text = {
    button_more: this.I18n.t('js.button_more'),
  };

  constructor(readonly I18n:I18nService) {
  }
}