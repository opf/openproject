import { ChangeDetectionStrategy, Component } from '@angular/core';
import { InAppNotificationsQuery } from 'core-app/features/in-app-notifications/store/in-app-notifications.query';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { InAppNotificationCenterComponent } from 'core-app/features/in-app-notifications/center/in-app-notification-center.component';
import { merge, timer } from 'rxjs';
import { filter, switchMap } from 'rxjs/operators';
import { ActiveWindowService } from 'core-app/core/active-window/active-window.service';

export const opInAppNotificationBellSelector = 'op-in-app-notification-bell';
const POLLING_INTERVAL = 10000;

@Component({
  selector: opInAppNotificationBellSelector,
  templateUrl: './in-app-notification-bell.component.html',
  styleUrls: ['./in-app-notification-bell.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationBellComponent {
  polling$ = timer(10, POLLING_INTERVAL)
    .pipe(
      filter(() => this.activeWindow.isActive),
      switchMap(() => this.inAppService.count$()),
    );

  unreadCount$ = merge(
    this.polling$,
    this.inAppQuery.unreadCount$,
  );

  constructor(readonly inAppQuery:InAppNotificationsQuery,
    readonly inAppService:InAppNotificationsService,
    readonly activeWindow:ActiveWindowService,
    readonly modalService:OpModalService) {
  }

  openCenter(event:MouseEvent) {
    this.modalService.show(InAppNotificationCenterComponent, 'global');
    event.preventDefault();
  }
}
