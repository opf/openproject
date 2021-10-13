import {
  Injectable,
  Injector,
} from '@angular/core';
import {
  map,
  mapTo,
  switchMap,
  take,
  debounceTime,
} from 'rxjs/operators';
import { ReplaySubject, from } from 'rxjs';
import {
  ID,
  setLoading,
} from '@datorama/akita';
import { NotificationsService } from "core-app/shared/components/notifications/notifications.service";
import {
  markNotificationsAsRead,
  notificationsMarkedRead,
  notificationCountIncreased,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { InAppNotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { IanCenterQuery } from 'core-app/features/in-app-notifications/center/state/ian-center.query';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { mapHALCollectionToIDCollection, selectCollectionAsHrefs$ } from 'core-app/core/state/collection-store';
import { INotificationPageQueryParameters } from 'core-app/features/in-app-notifications/in-app-notifications.routes';
import {
  IanCenterStore,
  InAppNotificationFacet,
} from './ian-center.store';

@Injectable()
@EffectHandler
export class IanCenterService {
  readonly id = 'ian-center';

  readonly store = new IanCenterStore();

  readonly query = new IanCenterQuery(this.store, this.resourceService);

  private reload = new ReplaySubject(1);
  private onReload = this.reload.pipe(
    debounceTime(0),
    switchMap(()=> this.resourceService
      .fetchNotifications(this.query.params)
      .pipe(
        setLoading(this.store),
        switchMap(
          (results) => from(this.sideLoadInvolvedWorkPackages(results._embedded.elements))
            .pipe(
              mapTo(mapHALCollectionToIDCollection(results)),
            )
        ),
      ),
    )
  );

  constructor(
    readonly injector:Injector,
    readonly resourceService:InAppNotificationsResourceService,
    readonly actions$:ActionsService,
    readonly apiV3Service:APIV3Service,
    readonly notificationsService:NotificationsService,
  ) {
    this.reload.subscribe();
  }

  setFilters(filters:INotificationPageQueryParameters):void {
    this.store.update({ filters });
    this.reload.next(0);
    this.onReload.pipe(take(1)).subscribe((collection) => {
      this.store.update({ activeCollection: collection });
    });
  }

  setFacet(facet:InAppNotificationFacet):void {
    this.store.update({ activeFacet: facet });
    this.reload.next(0);
    this.onReload.pipe(take(1)).subscribe((collection) => {
      this.store.update({ activeCollection: collection });
    });
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
   * Check for updates after bell count increased
   */
  @EffectCallback(notificationCountIncreased)
  private checkForNewNotifications(action:ReturnType<typeof notificationsMarkedRead>) {
    console.log('new notifications!');
    this.reload.next(0);
    this.onReload.pipe(take(1)).subscribe((collection) => {
      const activeCollection = this.query.getValue().activeCollection;
      const hasNewNotifications = !collection.ids.reduce(
        (allInOldCollection, id) => allInOldCollection && activeCollection.ids.includes(id),
        true,
      );

      if (!hasNewNotifications) {
        return;
      }

      this.notificationsService.add({
        type: 'info',
        message: 'There are new notifications.',
        link: {
          text: 'Click here to load them',
          target: () => {
            this.store.update({ activeCollection: collection });
          },
        },
      });
    });
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead(action:ReturnType<typeof notificationsMarkedRead>) {
    const activeCollection = this.query.getValue().activeCollection;
    this.store.update({
      activeCollection: {
        ids: activeCollection.ids.filter((activeID) => !action.notifications.includes(activeID)),
      },
    });
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
}
