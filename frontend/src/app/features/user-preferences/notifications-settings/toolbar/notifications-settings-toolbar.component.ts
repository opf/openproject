import { ChangeDetectionStrategy, Component } from '@angular/core';
import { UserPreferencesQuery } from 'core-app/features/user-preferences/state/user-preferences.query';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesStore } from 'core-app/features/user-preferences/state/user-preferences.store';

@Component({
  selector: 'op-notifications-settings-toolbar',
  templateUrl: './notifications-settings-toolbar.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsSettingsToolbarComponent {
  projectSettings$ = this.query.projectNotifications$;

  text = {
    title: this.I18n.t('js.notifications.settings.title'),
    remove_projects: this.I18n.t('js.notifications.settings.remove_projects'),
  };

  constructor(
    private query:UserPreferencesQuery,
    private store:UserPreferencesStore,
    private I18n:I18nService,
  ) {
  }

  removeAll():void {
    this.store.update(
      ({ notifications }) => ({
        notifications: notifications.filter((notification) => notification._links.project.href === null),
      }),
    );
  }
}
