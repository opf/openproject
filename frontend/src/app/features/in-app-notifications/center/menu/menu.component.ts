import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';

export const ianCenterMenuSelector = 'op-ian-menu';

@Component({
  selector: ianCenterMenuSelector,
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IANCenterMenuComponent {
  text = {
    title: this.I18n.t('js.notifications.title'),
    button_close: this.I18n.t('js.button_close'),
    no_results: {
      unread: this.I18n.t('js.notifications.no_unread'),
      all: this.I18n.t('js.notice_no_results_to_display'),
    },
  };

  constructor(
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
  ) {
    console.log('menu');
  }
}
