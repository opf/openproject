import { ChangeDetectionStrategy, Component, Input } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WpSingleViewService } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.service';

@Component({
  selector: 'op-work-package-mark-notification-button',
  templateUrl: './work-package-mark-notification-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageMarkNotificationButtonComponent {
  @Input() public workPackage:WorkPackageResource;

  @Input() public showWithText:boolean;

  text = {
    mark_as_read: this.I18n.t('js.notifications.center.mark_as_read'),
  };

  constructor(
    private I18n:I18nService,
    private storeService:WpSingleViewService,
  ) {
  }

  markAllBelongingNotificationsAsRead():void {
    this.storeService.markAllAsRead();
  }
}
