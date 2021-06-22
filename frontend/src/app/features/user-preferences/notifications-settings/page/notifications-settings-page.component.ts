import { ChangeDetectionStrategy, Component, ElementRef, Input, OnInit } from '@angular/core';
import { I18nService } from "core-app/core/i18n/i18n.service";
import { CurrentUserService } from "core-app/core/current-user/current-user.service";
import { take } from "rxjs/internal/operators/take";
import { arrayAdd } from "@datorama/akita";
import { HalSourceLink } from "core-app/features/hal/resources/hal-resource";
import { KeyValue } from "@angular/common";
import { UIRouterGlobals } from "@uirouter/core";
import { UserPreferencesService } from "core-app/features/user-preferences/state/user-preferences.service";
import { UserPreferencesStore } from "core-app/features/user-preferences/state/user-preferences.store";
import { UserPreferencesQuery } from "core-app/features/user-preferences/state/user-preferences.query";
import {
  buildNotificationSetting,
  NotificationSetting
} from "core-app/features/user-preferences/state/notification-setting.model";

export const myNotificationsPageComponentSelector = 'op-notifications-page';

@Component({
  selector: myNotificationsPageComponentSelector,
  templateUrl: './notifications-settings-page.component.html',
  styleUrls: ['./notifications-settings-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsSettingsPageComponent implements OnInit {
  @Input() userId:string;

  groupedNotificationSettings$ = this.query.notificationsGroupedByProject$;
  projectSettings$ = this.query.projectNotifications$;

  text = {
    title: this.I18n.t('js.notifications.settings.title'),
    save: this.I18n.t('js.button_save'),
    email: this.I18n.t('js.notifications.email'),
    inApp: this.I18n.t('js.notifications.in_app'),
    remove_projects: this.I18n.t('js.notifications.settings.remove_projects'),
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
    private currentUserService:CurrentUserService,
    private uiRouterGlobals:UIRouterGlobals
  ) {
  }

  ngOnInit():void {
    this.userId = this.userId || this.uiRouterGlobals.params.userId;
    this
      .currentUserService
      .user$
      .pipe(take(1))
      .subscribe(user => {
        this.userId = this.userId || user.id!;
        this.stateService.get(this.userId);
      });
  }

  public saveChanges():void {
    const notifications = this.query.getValue().notifications;
    this.stateService.update(this.userId, { notifications });
  }

  removeAll() {
    this.store.update(
      ({ notifications }) => ({
        notifications: notifications.filter(notification => notification._links.project.href === null)
      })
    );
  }

  addRow(project:HalSourceLink) {
    const added:NotificationSetting[] = [
      buildNotificationSetting(project, { channel: 'in_app' }),
      buildNotificationSetting(project, { channel: 'mail' }),
    ];

    this.store.update(
      ({ notifications }) => ({
        notifications: arrayAdd(notifications, added)
      })
    );
  }
}
