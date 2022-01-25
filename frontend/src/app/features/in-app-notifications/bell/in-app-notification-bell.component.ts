import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import {
  combineLatest,
  timer,
} from 'rxjs';
import {
  filter,
  map,
  switchMap,
} from 'rxjs/operators';
import { ActiveWindowService } from 'core-app/core/active-window/active-window.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';

export const opInAppNotificationBellSelector = 'op-in-app-notification-bell';
const POLLING_INTERVAL = 10000;

@Component({
  selector: opInAppNotificationBellSelector,
  templateUrl: './in-app-notification-bell.component.html',
  styleUrls: ['./in-app-notification-bell.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationBellComponent {
  polling$ = timer(10, POLLING_INTERVAL).pipe(
    filter(() => this.activeWindow.isActive),
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
    readonly modalService:OpModalService,
    readonly pathHelper:PathHelperService,
  ) { }

  notificationsPath():string {
    return this.pathHelper.notificationsPath();
  }
}
