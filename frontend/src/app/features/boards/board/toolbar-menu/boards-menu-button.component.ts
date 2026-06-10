import { ChangeDetectionStrategy, Component, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Board } from 'core-app/features/boards/board/board';
import { Observable } from 'rxjs';

@Component({
  template: `
    <button title="{{ text.button_more }}"
            class="button last board--settings-dropdown toolbar-icon"
            boardsToolbarMenu
            [boardsToolbarMenu-resource]="board$ | async">
      <op-icon icon-classes="button--icon icon-show-more" />
    </button>
  `,
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class BoardsMenuButtonComponent {
  readonly I18n = inject(I18nService);

  @Input() board$:Observable<Board>;

  text = {
    button_more: this.I18n.t('js.button_more'),
  };
}
