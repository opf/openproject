import { ChangeDetectionStrategy, Component } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'op-notification-settings-button',
  templateUrl: './notification-settings-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationSettingsButtonComponent {
  myNotificationSettingsLink = this.pathHelper.myNotificationsSettingsPath();

  text = {
    mySettings: this.I18n.t('js.notifications.settings.title'),
  };

  constructor(
    private I18n:I18nService,
    private pathHelper:PathHelperService,
  ) {
  }
}
