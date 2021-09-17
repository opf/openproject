import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import { ImmediateRemindersSettings } from 'core-app/features/user-preferences/state/user-preferences.model';
import { NotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';
import { arrayUpdate } from '@datorama/akita';

@Component({
  selector: 'op-email-alerts-settings',
  templateUrl: './email-alerts-settings.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EmailAlertsSettingsComponent {
  globalNotification$ = this.storeService.query.globalNotification$;

  alerts = [
    'newsAdded',
    'newsCommented',
    'documentAdded',
    'forumMessages',
    'wikiPageAdded',
    'wikiPageUpdated',
    'membershipAdded',
    'membershipUpdated',
  ];

  text = {
    newsAdded: this.I18n.t('js.reminders.settings.alerts.news_added'),
    newsCommented: this.I18n.t('js.reminders.settings.alerts.news_commented'),
    documentAdded: this.I18n.t('js.reminders.settings.alerts.document_added'),
    forumMessages: this.I18n.t('js.reminders.settings.alerts.forum_messages'),
    wikiPageAdded: this.I18n.t('js.reminders.settings.alerts.wiki_page_added'),
    wikiPageUpdated: this.I18n.t('js.reminders.settings.alerts.wiki_page_updated'),
    membershipAdded: this.I18n.t('js.reminders.settings.alerts.membership_added'),
    membershipUpdated: this.I18n.t('js.reminders.settings.alerts.membership_updated'),
  };

  constructor(
    private I18n:I18nService,
    private storeService:UserPreferencesService,
  ) {
  }

  toggleEnabled(key:string, enabled:boolean) {
    const delta = { [key]: enabled };
    this.storeService.store.update(
      ({ notifications }) => ({
        notifications: arrayUpdate(
          notifications, this.matcherFn.bind(this), delta,
        ),
      }),
    );
  }

  private matcherFn(notification:NotificationSetting) {
    return !notification._links.project.href;
  }
}
