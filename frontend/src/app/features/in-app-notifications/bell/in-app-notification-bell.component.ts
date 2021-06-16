import { Component, OnInit, ChangeDetectionStrategy, HostListener } from '@angular/core';
import { InAppNotificationsQuery } from "core-app/features/in-app-notifications/store/in-app-notifications.query";
import { InAppNotificationsService } from "core-app/features/in-app-notifications/store/in-app-notifications.service";
import { OpModalService } from "core-app/shared/components/modal/modal.service";
import { InAppNotificationCenterComponent } from "core-app/features/in-app-notifications/center/in-app-notification-center.component";

export const opInAppNotificationBellSelector = 'op-in-app-notification-bell';

@Component({
  selector: opInAppNotificationBellSelector,
  templateUrl: './in-app-notification-bell.component.html',
  styleUrls: ['./in-app-notification-bell.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationBellComponent implements OnInit {
  constructor(readonly inAppQuery:InAppNotificationsQuery,
              readonly inAppService:InAppNotificationsService,
              readonly modalService:OpModalService) {
  }

  ngOnInit():void {
    this.inAppService.get();
  }

  openCenter(event:MouseEvent) {
    this.modalService.show(InAppNotificationCenterComponent, 'global');
    event.preventDefault();
  }
}
