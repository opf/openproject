import { ChangeDetectionStrategy, Component, ElementRef, Input, OnInit } from '@angular/core';
import { I18nService } from "core-app/core/i18n/i18n.service";
import { NotificationSettingsService } from "core-app/features/my-account/my-notifications-page/state/notification-settings.service";
import { NotificationSettingsQuery } from "core-app/features/my-account/my-notifications-page/state/notification-settings.query";
import { CurrentUserService } from "core-app/core/current-user/current-user.service";
import { take } from "rxjs/internal/operators/take";
import { NotificationSettingProjectOption } from "core-app/features/my-account/my-notifications-page/inline-create/notification-setting-inline-create.component";
import { NotificationSettingsStore } from "core-app/features/my-account/my-notifications-page/state/notification-settings.store";
import { arrayAdd } from "@datorama/akita";
import {
  buildNotificationSetting,
  NotificationSetting
} from "core-app/features/my-account/my-notifications-page/state/notification-setting.model";
import { HalSourceLink } from "core-app/features/hal/resources/hal-resource";
import { KeyValue } from "@angular/common";
import { UIRouterGlobals } from "@uirouter/core";

export const myNotificationsPageComponentSelector = 'op-notifications-page';

@Component({
  selector: myNotificationsPageComponentSelector,
  templateUrl: './my-notifications-page.component.html',
  styleUrls: ['./my-notifications-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MyNotificationsPageComponent implements OnInit {
  @Input() userId:string;

  groupedNotificationSettings$ = this.query.groupedByProject$;
  projectSettings$ = this.query.projectSettings$;

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
    private stateService:NotificationSettingsService,
    private store:NotificationSettingsStore,
    private query:NotificationSettingsQuery,
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
    this.stateService.update(this.userId, notifications);
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
