import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import {
  combineLatest,
  merge,
  timer,
} from 'rxjs';
import {
  filter,
  map,
  switchMap,
  throttleTime,
} from 'rxjs/operators';
import { ActiveWindowService } from 'core-app/core/active-window/active-window.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';

export const opInAppNotificationBellSelector = 'op-in-app-notification-bell';
const ACTIVE_POLLING_INTERVAL = 10000;
const INACTIVE_POLLING_INTERVAL = 120000;

@Component({
  selector: opInAppNotificationBellSelector,
  templateUrl: './in-app-notification-bell.component.html',
  styleUrls: ['./in-app-notification-bell.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationBellComponent {
  polling$ = merge(
    timer(10, ACTIVE_POLLING_INTERVAL).pipe(filter(() => this.activeWindow.isActive)),
    timer(10, INACTIVE_POLLING_INTERVAL).pipe(filter(() => !this.activeWindow.isActive)),
  )
    .pipe(
      throttleTime(ACTIVE_POLLING_INTERVAL),
      switchMap(() => this.storeService.fetchUnread()),
    );

  unreadCount$ = combineLatest([
    this.storeService.unread$,
    this.polling$,
  ]).pipe(map(([count]) => count));

  constructor(
    readonly storeService:IanBellService,
    readonly apiV3Service:ApiV3Service,
    readonly activeWindow:ActiveWindowService,
    readonly pathHelper:PathHelperService,
  ) { }

  notificationsPath():string {
    return this.pathHelper.notificationsPath();
  }
}
