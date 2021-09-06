// noinspection ES6UnusedImports

import {
  Component,
  ChangeDetectionStrategy,
  Input,
} from '@angular/core';
import { map } from 'rxjs/operators';
import { KeyValue } from '@angular/common';
import { arrayAdd, arrayUpdate, arrayRemove } from '@datorama/akita';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesStore } from 'core-app/features/user-preferences/state/user-preferences.store';
import { UserPreferencesQuery } from 'core-app/features/user-preferences/state/user-preferences.query';
import { HalSourceLink } from 'core-app/features/hal/resources/hal-resource';
import {
  buildNotificationSetting,
  NotificationSetting,
} from 'core-app/features/user-preferences/state/notification-setting.model';

@Component({
  selector: 'op-notification-settings-table',
  templateUrl: './notification-settings-table.component.html',
  styleUrls: ['./notification-settings-table.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationSettingsTableComponent {
  @Input() userId:string;

  groupedNotificationSettings$ = this.query.notificationsGroupedByProject$;

  showTable$ = this.query.notificationsGroupedByProject$.pipe(map((settings) => Object.keys(settings).length > 0));

  text = {
    save: this.I18n.t('js.button_save'),

    mentioned_header: this.I18n.t('js.notifications.settings.reasons.mentioned.title'),
    involved_header: this.I18n.t('js.notifications.settings.reasons.involved.title'),
    watched_header: this.I18n.t('js.notifications.settings.reasons.watched'),
    work_package_commented_header: this.I18n.t('js.notifications.settings.reasons.work_package_commented'),
    work_package_created_header: this.I18n.t('js.notifications.settings.reasons.work_package_created'),
    work_package_processed_header: this.I18n.t('js.notifications.settings.reasons.work_package_processed'),
    work_package_prioritized_header: this.I18n.t('js.notifications.settings.reasons.work_package_prioritized'),
    work_package_scheduled_header: this.I18n.t('js.notifications.settings.reasons.work_package_scheduled'),
  };

  projectOrder = (a:KeyValue<string, unknown>, b:KeyValue<string, unknown>):number => {
    return a.key.localeCompare(b.key);
  };

  constructor(
    private I18n:I18nService,
    private store:UserPreferencesStore,
    private query:UserPreferencesQuery,
  ) {}

  addRow(project:HalSourceLink):void {
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

  update(delta:Partial<NotificationSetting>, projectHref:string):void {
    this.store.update(
      ({ notifications }) => ({
        notifications: arrayUpdate(
          notifications,
          (notification:NotificationSetting) => notification._links.project.href === projectHref,
          delta,
        ),
      }),
    );
  }

  removeProjectSettings(projectHref:string):void {
    this.store.update(
      ({ notifications }) => ({
        notifications: arrayRemove(notifications, (notification:NotificationSetting) => notification._links.project.href === projectHref),
      }),
    );
  }
}
