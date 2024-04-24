import { Component, ChangeDetectionStrategy } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { videoPath } from 'core-app/shared/helpers/videos/path-helper';

@Component({
  selector: 'op-ian-date-alerts-upsale',
  templateUrl: './ian-date-alerts-upsale.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationsDateAlertsUpsaleComponent {
  video = videoPath('notification-center/date-alert-notifications.mp4');

  text = {
    title: this.I18n.t('js.notifications.date_alerts.upsale.title'),
    description: this.I18n.t('js.notifications.date_alerts.upsale.description'),
  };

  constructor(
    readonly I18n:I18nService,
  ) { }
}
