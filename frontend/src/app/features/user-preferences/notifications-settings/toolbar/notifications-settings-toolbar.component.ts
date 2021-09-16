import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';

@Component({
  selector: 'op-notifications-settings-toolbar',
  templateUrl: './notifications-settings-toolbar.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsSettingsToolbarComponent {
  projectSettings$ = this.storeService.query.projectNotifications$;

  text = {
    title: this.I18n.t('js.notifications.settings.title'),
  };

  constructor(
    private storeService:UserPreferencesService,
    private I18n:I18nService,
  ) {
  }

  removeAll():void {
    this.storeService.store.update(
      ({ notifications }) => ({
        notifications: notifications.filter((notification) => notification._links.project.href === null),
      }),
    );
  }
}
