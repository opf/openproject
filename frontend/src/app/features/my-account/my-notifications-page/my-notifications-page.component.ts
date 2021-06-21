import {
  ApplicationRef,
  ChangeDetectionStrategy,
  Component,
  ComponentFactoryResolver,
  ElementRef,
  Injector,
  OnInit,
  ViewChild,
} from '@angular/core';
import { I18nService } from "core-app/core/i18n/i18n.service";
import { FormControl, FormGroup } from "@angular/forms";
import { MyNotificationsPageService } from "core-app/features/my-account/my-notifications-page/my-notifications-page.service";
import { NotificationSettingsQuery } from "core-app/features/my-account/my-notifications-page/notification-settings.query";
import { Observable } from "rxjs";
import { NotificationSetting } from "core-app/features/my-account/my-notifications-page/notification-settings.store";

@Component({
  templateUrl: './my-notifications-page.component.html',
  styleUrls: ['./my-notifications-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MyNotificationsPageComponent implements OnInit {

  public notificationSettings$: Observable<NotificationSetting[]>;

  text = {
    save: this.I18n.t('js.button_save'),
    enable: this.I18n.t('js.notifications.settings.enable_app_notifications'),
    email: this.I18n.t('js.notifications.email'),
    inApp: this.I18n.t('js.notifications.in_app'),
  };

  form = new FormGroup({
    enabled: new FormControl(''),
  });

  get enabledControl() {
    return this.form.get('enabled');
  }

  constructor(
    private I18n:I18nService,
    private myNotificationPageService: MyNotificationsPageService,
    private notificationSettingsQuery: NotificationSettingsQuery
  ) {
  }

  ngOnInit():void {
    this.notificationSettings$ = this.notificationSettingsQuery.select();
  }

  public saveChanges():void {
    this.submit();
  }

  private submit():void {
  }
}
