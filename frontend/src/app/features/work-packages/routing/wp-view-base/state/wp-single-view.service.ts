import { Injectable } from '@angular/core';
import { WpSingleViewStore } from './wp-single-view.store';
import {
  filter,
  map,
  switchMap,
  take,
} from 'rxjs/operators';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import {
  ApiV3ListFilter,
  ApiV3ListParameters,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  centerUpdatedInPlace,
  markNotificationsAsRead,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { Query } from '@datorama/akita';

@EffectHandler
@Injectable()
export class WpSingleViewService {
  id = 'WorkPackage Activity Store';

  protected store = new WpSingleViewStore();

  protected query = new Query(this.store);

  selectNotifications$ = this
    .query
    .select((state) => state.notifications.filters)
    .pipe(
      filter((filters) => filters.length > 0),
      switchMap((filters) => this.resourceService.collection({ filters })),
    );

  selectNotificationsCount$ = this
    .selectNotifications$
    .pipe(
      map((notifications) => notifications.length),
    );

  nonDateAlertNotificationsCount$ = this
    .selectNotifications$
    .pipe(
      map((notifications) => notifications.filter((notification) => notification.reason !== 'dateAlert')),
      map((notifications) => notifications.length),
    );

  hasNotifications$ = this
    .selectNotificationsCount$
    .pipe(
      map((count) => count > 0),
    );

  get params():ApiV3ListParameters {
    return { filters: this.query.getValue().notifications.filters };
  }

  constructor(
    readonly actions$:ActionsService,
    readonly currentUser$:CurrentUserService,
    private resourceService:InAppNotificationsResourceService,
  ) {
  }

  setFilters(workPackageId:string):void {
    const filters:ApiV3ListFilter[] = [
      ['readIAN', '=', false],
      ['resourceId', '=', [workPackageId]],
      ['resourceType', '=', ['WorkPackage']],
    ];

    this.store.update(({ notifications }) => (
      {
        notifications: {
          ...notifications,
          filters,
        },
      }
    ));

    this.reload();
  }

  markAllAsRead():void {
    this
      .resourceService
      .collection({ filters: this.store.getValue().notifications.filters })
      .pipe(
        take(1),
      )
      .subscribe((collection) => {
        this.actions$.dispatch(
          markNotificationsAsRead({ origin: this.id, notifications: collection.map((el) => el.id) }),
        );
      });
  }

  private reload() {
    this
      .currentUser$
      .isLoggedIn$
      .pipe(
        take(1),
        filter((loggedIn) => loggedIn),
        switchMap(() => this.resourceService.fetchCollection(this.params)),
      )
      .subscribe();
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead() {
    this.reload();
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(centerUpdatedInPlace)
  private reloadOnCenterUpdate() {
    this.reload();
  }
}
