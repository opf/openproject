import { ChangeDetectionStrategy, Component } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'op-notifications-settings-toolbar',
  templateUrl: './notifications-settings-toolbar.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsSettingsToolbarComponent {
  text = {
    title: this.I18n.t('js.notifications.settings.title'),
  };

  constructor(
    private I18n:I18nService,
  ) { }
}
