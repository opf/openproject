// noinspection ES6UnusedImports

import {
  Component, OnInit, ChangeDetectionStrategy, Input,
} from '@angular/core';
import { KeyValue } from '@angular/common';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import { UserPreferencesStore } from 'core-app/features/user-preferences/state/user-preferences.store';
import { UserPreferencesQuery } from 'core-app/features/user-preferences/state/user-preferences.query';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { UIRouterGlobals } from '@uirouter/core';
import { HalSourceLink } from 'core-app/features/hal/resources/hal-resource';
import {
  buildNotificationSetting,
  NotificationSetting,
} from 'core-app/features/user-preferences/state/notification-setting.model';
import { arrayAdd } from '@datorama/akita';

@Component({
  selector: 'op-notification-settings-table',
  templateUrl: './notification-settings-table.component.html',
  styleUrls: ['./notification-settings-table.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationSettingsTableComponent {
  @Input() userId:string;

  groupedNotificationSettings$ = this.query.notificationsGroupedByProject$;

  text = {
    save: this.I18n.t('js.button_save'),
    involved_header: this.I18n.t('js.notifications.settings.involved'),
    channel_header: this.I18n.t('js.notifications.channel'),
    mentioned_header: this.I18n.t('js.notifications.settings.mentioned'),
    watched_header: this.I18n.t('js.notifications.settings.watched'),
    any_event_header: this.I18n.t('js.notifications.settings.all'),
    default_all_projects: this.I18n.t('js.notifications.settings.default_all_projects'),
  };

  projectOrder = (a:KeyValue<string, unknown>, b:KeyValue<string, unknown>):number => {
    if (a.key === 'global') {
      return -1;
    }

    if (b.key === 'global') {
      return 1;
    }

    return a.key.localeCompare(b.key);
  };

  constructor(
    private I18n:I18nService,
    private stateService:UserPreferencesService,
    private store:UserPreferencesStore,
    private query:UserPreferencesQuery,
  ) {
  }

  addRow(project:HalSourceLink) {
    const added:NotificationSetting[] = [
      buildNotificationSetting(project, { channel: 'in_app' }),
      buildNotificationSetting(project, { channel: 'mail' }),
      buildNotificationSetting(project, { channel: 'mail_digest' }),
    ];

    this.store.update(
      ({ notifications }) => ({
        notifications: arrayAdd(notifications, added),
      }),
    );
  }
}
