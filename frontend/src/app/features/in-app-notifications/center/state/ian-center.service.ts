import {
  Injectable,
  Injector,
} from '@angular/core';
import {
  IanCenterStore,
  InAppNotificationFacet,
} from './ian-center.store';
import {
  map,
  switchMap,
  take,
} from 'rxjs/operators';
import {
  markNotificationsAsRead,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { InAppNotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { IanCenterQuery } from 'core-app/features/in-app-notifications/center/state/ian-center.query';
import {
  ID,
  setLoading,
} from '@datorama/akita';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { from } from 'rxjs';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { selectCollectionAsHrefs$ } from 'core-app/core/state/collection-store';
import { StateService } from '@uirouter/angular';
import { BackRouteOptions } from 'core-app/features/work-packages/components/back-routing/back-routing.service';

@Injectable()
@EffectHandler
export class IanCenterService {
  readonly id = 'ian-center';

  readonly store = new IanCenterStore();

  readonly query = new IanCenterQuery(this.store, this.resourceService);

  public selectedNotificationIndex = 0;

  constructor(
    readonly injector:Injector,
    readonly resourceService:InAppNotificationsResourceService,
    readonly actions$:ActionsService,
    readonly apiV3Service:APIV3Service,
    readonly state:StateService,
  ) {
  }

  setFacet(facet:InAppNotificationFacet):void {
    this.store.update({ activeFacet: facet });
    this.reload();
  }

  markAsRead(notifications:ID[]):void {
    this.actions$.dispatch(
      markNotificationsAsRead({ origin: this.id, notifications }),
    );
  }

  markAllAsRead():void {
    selectCollectionAsHrefs$(this.resourceService, this.query.params)
      .pipe(
        take(1),
      )
      .subscribe((collection) => {
        this.markAsRead(collection.ids);
      });
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead(action:ReturnType<typeof notificationsMarkedRead>) {
    this.beforeReloadNotifications(action.notifications[0]);
    this.resourceService.removeFromCollection(this.query.params, action.notifications);
    this.afterReloadNotifications(this.selectedNotificationIndex);
  }

  private reload() {
    this.resourceService
      .fetchNotifications(this.query.params)
      .pipe(
        setLoading(this.store),
        switchMap((results) => from(this.sideLoadInvolvedWorkPackages(results._embedded.elements))),
      )
      .subscribe();
  }

  private sideLoadInvolvedWorkPackages(elements:InAppNotification[]):Promise<unknown> {
    const { cache } = this.apiV3Service.work_packages;
    const wpIds = elements
      .map((element) => {
        const href = element._links.resource?.href;
        return href && HalResource.matchFromLink(href, 'work_packages');
      })
      .filter((id) => id && cache.stale(id)) as string[];

    const promise = this
      .apiV3Service
      .work_packages
      .requireAll(_.compact(wpIds));

    wpIds.forEach((id) => {
      cache.clearAndLoad(
        id,
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        from(promise).pipe(map(() => cache.current(id)!)),
      );
    });

    return promise;
  }

  private afterReloadNotifications(notificationIndex:number) {
    if (window.location.href.indexOf('details') <= -1) {
      return;
    }
    this.query.notifications$.pipe(take(1)).subscribe((notifications) => {
      if (notifications.length <= 0) {
          void this.state.go(
            `${(this.state.current.data as BackRouteOptions).baseRoute}`,
          );
      } else {
          const index = notificationIndex > notifications.length ? 0 : notificationIndex - 1;
          const href = notifications[index][0]._links.resource?.href;
          const id = href && HalResource.matchFromLink(href, 'work_packages');
          if (id) {
            const wp = this
              .apiV3Service
              .work_packages
              .id(id)
              .requireAndStream();

            wp.pipe(take(1))
              .subscribe((workPackage) => {
                void this.state.go(
                  `${(this.state.current.data as BackRouteOptions).baseRoute}.details.tabs`,
                  { workPackageId: workPackage.id, tabIdentifier: 'activity' },
                );
            });
          }
        }
    });
  }

  private beforeReloadNotifications(notificationID:string | number) {
    this.query.notifications$.pipe().subscribe((wpNotifications) => {
      let counter = 0;
      wpNotifications.forEach((wpNotification) => {
        counter = counter + 1;
        wpNotification.forEach((notification) => {
          if (notification.id === notificationID) {
            this.selectedNotificationIndex = counter;
          }
        });
      });
    });
  }
}
