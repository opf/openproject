import { Component, Input } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Board } from 'core-app/features/boards/board/board';
import { Observable } from 'rxjs';

@Component({
  template: `
    <button
      [attr.title]="text.button_more"
      [attr.aria-label]="text.button_more"
      class="button -icon-only last board--settings-dropdown toolbar-icon"
      boardsToolbarMenu
      [boardsToolbarMenu-resource]="board$ | async"
    >
      <span class="spot-icon spot-icon_show-more"></span>
    </button>
  `,
})
export class BoardsMenuButtonComponent {
  @Input() board$:Observable<Board>;

  text = {
    button_more: this.I18n.t('js.button_more'),
  };

  constructor(readonly I18n:I18nService) {
  }
}
