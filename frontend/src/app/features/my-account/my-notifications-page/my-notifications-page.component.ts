import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { I18nService } from "core-app/core/i18n/i18n.service";
import { NotificationSettingsService } from "core-app/features/my-account/my-notifications-page/state/notification-settings.service";
import { NotificationSettingsQuery } from "core-app/features/my-account/my-notifications-page/state/notification-settings.query";

@Component({
  selector: 'op-notifications-page',
  templateUrl: './my-notifications-page.component.html',
  styleUrls: ['./my-notifications-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MyNotificationsPageComponent implements OnInit {
  @Input() userId:string = 'me';
  public notificationSettings$ = this.query.notificationSettings$;

  text = {
    title: this.I18n.t('js.notifications.settings.title'),
    save: this.I18n.t('js.button_save'),
    email: this.I18n.t('js.notifications.email'),
    inApp: this.I18n.t('js.notifications.in_app'),
    remove_all: this.I18n.t('js.notifications.settings.remove_all'),
    involved_header: 'I am involved',
    mentioned_header: 'I was mentioned',
    watched_header: 'I am watching',
    any_event_header: 'All events',
    default_all_projects: 'Default for all projects',
  };

  constructor(
    private I18n:I18nService,
    private stateService:NotificationSettingsService,
    private query:NotificationSettingsQuery,
  ) {
  }

  ngOnInit():void {
    this.stateService.get(this.userId);
  }

  public saveChanges():void {
    const notifications = this.query.getValue().notifications;
    this.stateService.update(this.userId, notifications);
  }

  removeAll() {

  }
}
