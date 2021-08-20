import { Component, ChangeDetectionStrategy, Input, OnInit } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { InAppNotification } from 'core-app/features/in-app-notifications/store/in-app-notification.model';

@Component({
  selector: 'op-work-package-mark-notification-button',
  templateUrl: './work-package-mark-notification-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageMarkNotificationButtonComponent implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  @Input() public buttonClasses:string;

  private belongingNotifications:InAppNotification[];

  text = {
    mark_as_read: this.I18n.t('js.notifications.center.mark_as_read'),
  };

  constructor(
    private I18n:I18nService,
    private ianService:InAppNotificationsService,
  ) {
  }

  ngOnInit():void {
    this
      .ianService
      .notificationsOfWpLoaded
      .subscribe((notifications) => {
        this.belongingNotifications = notifications._embedded.elements;
      });
  }

  markAllBelongingWPsAsRead():void {
    this.ianService.markAsRead(this.belongingNotifications);
  }
}
