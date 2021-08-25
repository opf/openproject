import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { InAppNotificationsQuery } from 'core-app/features/in-app-notifications/store/in-app-notifications.query';
import { InAppNotificationsStore } from 'core-app/features/in-app-notifications/store/in-app-notifications.store';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { timer, combineLatest } from 'rxjs';
import {
  filter,
  switchMap,
  tap,
  map,
} from 'rxjs/operators';
import { ActiveWindowService } from 'core-app/core/active-window/active-window.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

export const opInAppNotificationBellSelector = 'op-in-app-notification-bell';
const POLLING_INTERVAL = 10000;

@Component({
  selector: opInAppNotificationBellSelector,
  templateUrl: './in-app-notification-bell.component.html',
  styleUrls: ['./in-app-notification-bell.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    InAppNotificationsService,
    InAppNotificationsStore,
    InAppNotificationsQuery,
  ],
})
export class InAppNotificationBellComponent implements OnInit {
  polling$ = timer(10, POLLING_INTERVAL).pipe(
    filter(() => this.activeWindow.isActive),
    tap(() => console.log('sending fetch request from bell')),
    switchMap(() => this.inAppService.fetchNotifications()),
  );

  unreadCount$ = combineLatest([
    this.inAppQuery.notLoaded$,
    this.polling$,
  ]).pipe(map(([count]) => count));

  constructor(
    readonly inAppQuery:InAppNotificationsQuery,
    readonly inAppService:InAppNotificationsService,
    readonly activeWindow:ActiveWindowService,
    readonly modalService:OpModalService,
    readonly pathHelper:PathHelperService,
  ) { }

  ngOnInit():void {
    this.inAppService.setPageSize(0);
  }

  notificationsPath():string {
    return this.pathHelper.notificationsPath();
  }
}
