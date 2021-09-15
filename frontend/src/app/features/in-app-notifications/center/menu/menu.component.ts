import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';

export const ianCenterMenuSelector = 'op-ian-menu';

@Component({
  selector: ianCenterMenuSelector,
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IANCenterMenuComponent implements OnInit {
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
    readonly resourceService:InAppNotificationsResourceService,
  ) {
    console.log('menu');
  }

  ngOnInit() {
    this.resourceService.fetchNotifications({
      pageSize: 0,
      groupBy: 'project',
      filters: [['unread', '=', true]],
    });
  }
}
