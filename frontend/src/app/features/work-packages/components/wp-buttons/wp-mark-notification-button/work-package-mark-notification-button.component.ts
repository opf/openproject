import { ChangeDetectionStrategy, Component, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WpSingleViewService } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.service';

@Component({
  selector: 'op-work-package-mark-notification-button',
  templateUrl: './work-package-mark-notification-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageMarkNotificationButtonComponent {
  private I18n = inject(I18nService);
  private storeService = inject(WpSingleViewService);

  @Input() public workPackage:WorkPackageResource;

  text = {
    mark_as_read: this.I18n.t('js.notifications.center.mark_as_read'),
  };

  markAllBelongingNotificationsAsRead():void {
    this.storeService.markAllAsRead();
    // emit custom event in order to inform the activity tab stimulus controller
    // will trigger an update of the activities list
    document.dispatchEvent(
      new CustomEvent('work-package-notifications-updated'),
    );
  }
}
