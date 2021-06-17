import { Component, OnInit, ChangeDetectionStrategy, HostListener } from '@angular/core';
import { InAppNotificationsQuery } from "core-app/features/in-app-notifications/store/in-app-notifications.query";
import { InAppNotificationsService } from "core-app/features/in-app-notifications/store/in-app-notifications.service";
import { OpModalService } from "core-app/shared/components/modal/modal.service";
import { InAppNotificationCenterComponent } from "core-app/features/in-app-notifications/center/in-app-notification-center.component";
import { UntilDestroyedMixin } from "core-app/shared/helpers/angular/until-destroyed.mixin";
import { interval } from "rxjs";
import { filter, startWith, switchMap } from "rxjs/operators";
import { ActiveWindowService } from "core-app/core/active-window/active-window.service";

export const opInAppNotificationBellSelector = 'op-in-app-notification-bell';
const POLLING_INTERVAL = 10000;

@Component({
  selector: opInAppNotificationBellSelector,
  templateUrl: './in-app-notification-bell.component.html',
  styleUrls: ['./in-app-notification-bell.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationBellComponent {
  unreadCount$ = interval(POLLING_INTERVAL)
    .pipe(
      startWith(0),
      filter(() => this.activeWindow.isActive),
      switchMap(() => this.inAppService.count$()),
      filter(count => count > 0)
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
