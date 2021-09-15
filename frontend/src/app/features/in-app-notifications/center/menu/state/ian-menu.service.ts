import {
  Injectable,
  Injector,
} from '@angular/core';
import {
  map,
  take,
} from 'rxjs/operators';
import { from } from 'rxjs';
import { ID } from '@datorama/akita';
import {
  markNotificationsAsRead,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { InAppNotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { selectCollectionAsHrefs$ } from 'core-app/core/state/collection-store';
import { IanMenuQuery } from './ian-menu.query';
import {
  IanMenuStore,
  IAN_MENU_PROJECT_FILTERS,
  IAN_MENU_REASON_FILTERS,
} from './ian-menu.store';

@Injectable()
@EffectHandler
export class IanMenuService {
  readonly id = 'ian-center';

  readonly store = new IanMenuStore();

  readonly query = new IanMenuQuery(this.store, this.resourceService);

  constructor(
    readonly injector:Injector,
    readonly resourceService:InAppNotificationsResourceService,
    readonly actions$:ActionsService,
    readonly apiV3Service:APIV3Service,
  ) {
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead() {
    return this.reload();
  }

  public reload() {
    this.resourceService.fetchNotifications(IAN_MENU_PROJECT_FILTERS)
      .subscribe((data) => this.store.update({ notificationsByProject: data.groups }));
    this.resourceService.fetchNotifications(IAN_MENU_REASON_FILTERS)
      .subscribe((data) => this.store.update({ notificationsByReason: data.groups }));
  }
}
