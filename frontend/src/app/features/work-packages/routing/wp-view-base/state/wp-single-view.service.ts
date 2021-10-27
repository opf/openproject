import { Injectable } from '@angular/core';
import { WpSingleViewStore } from './wp-single-view.store';
import { WpSingleViewQuery } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.query';
import {
  filter,
  switchMap,
  take,
} from 'rxjs/operators';
import { selectCollectionAsHrefs$ } from 'core-app/core/state/collection-store';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  markNotificationsAsRead,
  notificationsMarkedRead,
  centerUpdatedInPlace,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';

@EffectHandler
@Injectable()
export class WpSingleViewService {
  id = 'WorkPackage Activity Store';

  protected store = new WpSingleViewStore();

  readonly query = new WpSingleViewQuery(this.store, this.resourceService);

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
    selectCollectionAsHrefs$(this.resourceService, { filters: this.store.getValue().notifications.filters })
      .pipe(
        take(1),
      )
      .subscribe((collection) => {
        this.actions$.dispatch(
          markNotificationsAsRead({ origin: this.id, notifications: collection.ids }),
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
        switchMap(() => this.resourceService.fetchNotifications(this.query.params)),
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
