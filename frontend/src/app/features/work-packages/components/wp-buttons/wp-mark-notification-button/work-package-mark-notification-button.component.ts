import { Component, ChangeDetectionStrategy, Input } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Component({
  selector: 'op-work-package-mark-notification-button',
  templateUrl: './work-package-mark-notification-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageMarkNotificationButtonComponent {
  @Input() public workPackage:WorkPackageResource;

  @Input() public buttonClasses:string;

  text = {
    mark_as_read: this.I18n.t('js.notifications.center.mark_as_read'),
  };

  constructor(
    private I18n:I18nService,
    private ianService:InAppNotificationsService,
  ) {
  }

  markAllBelongingWPsAsRead():void {
    // TODO
    this.ianService.markAllRead();
  }
}
