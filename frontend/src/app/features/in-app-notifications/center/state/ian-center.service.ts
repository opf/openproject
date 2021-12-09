import {
  Injectable,
  Injector,
} from '@angular/core';
import {
  debounceTime,
  distinctUntilChanged,
  map,
  mapTo,
  pluck,
  shareReplay,
  switchMap,
  take,
} from 'rxjs/operators';
import {
  from,
  Subject,
} from 'rxjs';
import {
  ID,
  setLoading,
} from '@datorama/akita';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import {
  centerUpdatedInPlace,
  markNotificationsAsRead,
  notificationCountIncreased,
  notificationsMarkedRead,
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
import {
  mapHALCollectionToIDCollection,
  selectCollectionAsEntities$,
  selectCollectionAsHrefs$,
} from 'core-app/core/state/collection-store';
import { INotificationPageQueryParameters } from 'core-app/features/in-app-notifications/in-app-notifications.routes';
import {
  IanCenterStore,
  InAppNotificationFacet,
} from './ian-center.store';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { UIRouterGlobals } from '@uirouter/core';
import { StateService } from '@uirouter/angular';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { DeviceService } from 'core-app/core/browser/device.service';
import { OpTitleService } from 'core-app/core/html/op-title.service';

@Injectable()
@EffectHandler
export class IanCenterService extends UntilDestroyedMixin {
  readonly id = 'ian-center';

  readonly store = new IanCenterStore();

  readonly query = new IanCenterQuery(this.store, this.resourceService);

  private reload = new Subject();

  private onReload = this.reload.pipe(
    debounceTime(0),
    switchMap((setToLoading) => this.resourceService
      .fetchNotifications(this.query.params)
      .pipe(
        // We don't want to set loading if the request is sent in the background
        setToLoading ? setLoading(this.store) : map((res) => res),
        switchMap(
          (results) => from(this.sideLoadInvolvedWorkPackages(results._embedded.elements))
            .pipe(
              mapTo(mapHALCollectionToIDCollection(results)),
            ),
        ),
      )),
  );

  public selectedNotificationIndex = 0;

  stateChanged$ = this.uiRouterGlobals.params$?.pipe(
    this.untilDestroyed(),
    pluck('workPackageId'),
    distinctUntilChanged(),
    map((workPackageId:string) => (workPackageId ? this.apiV3Service.work_packages.id(workPackageId).path : undefined)),
    shareReplay(),
  );

  constructor(
    readonly I18n:I18nService,
    readonly injector:Injector,
    readonly resourceService:InAppNotificationsResourceService,
    readonly actions$:ActionsService,
    readonly apiV3Service:APIV3Service,
    readonly toastService:ToastService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly state:StateService,
    readonly deviceService:DeviceService,
    readonly titleService:OpTitleService,
  ) {
    super();
    this.reload.subscribe();

    if (this.stateChanged$) {
      this.stateChanged$.subscribe(() => {
        this.updateSelectedNotificationIndex();
      });
    }
  }

  setFilters(filters:INotificationPageQueryParameters):void {
    this.store.update({ filters });
    this.onReload.pipe(take(1)).subscribe((collection) => {
      this.store.update({ activeCollection: collection });
    });
    this.reload.next(true);
  }

  setFacet(facet:InAppNotificationFacet):void {
    this.store.update({ activeFacet: facet });
    this.onReload.pipe(take(1)).subscribe((collection) => {
      this.store.update({ activeCollection: collection });
    });
    this.reload.next(true);
  }

  markAsRead(notifications:ID[]):void {
    this.actions$.dispatch(
      markNotificationsAsRead({ origin: this.id, notifications }),
    );
  }

  markAllAsRead():void {
    const ids:ID[] = selectCollectionAsEntities$(this.resourceService, this.resourceService.query.getValue(), this.query.params)
      .filter((notification) => notification.readIAN === false)
      .map((notification) => notification.id);

    if (ids.length > 0) {
      this.markAsRead(ids);
    }
  }

  openSplitScreen(wpId:string|null):void {
    void this.state.go(
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/restrict-template-expressions
      `${this.state.current.data.baseRoute}.details.tabs`,
      { workPackageId: wpId, tabIdentifier: 'activity' },
    );
  }

  showNextNotification():void {
    void this
      .query
      .notifications$
      .pipe(
        take(1),
      ).subscribe((notifications:InAppNotification[][]) => {
        if (notifications.length <= 0) {
          void this.state.go(
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/restrict-template-expressions
            `${this.state.current.data.baseRoute}`,
          );
          this.titleService.setFirstPart('OpenProject');
          return;
        }
        if (notifications[0][0]._links.resource || notifications[this.selectedNotificationIndex][0]._links.resource) {
          const wpId = idFromLink(notifications[this.selectedNotificationIndex >= notifications.length ? 0 : this.selectedNotificationIndex][0]._links.resource.href);
          this.openSplitScreen(wpId);
        }
      });
  }

  /**
   * Check for updates after bell count increased
   */
  @EffectCallback(notificationCountIncreased)
  private checkForNewNotifications() {
    this.onReload.pipe(take(1)).subscribe((collection) => {
      const { activeCollection } = this.query.getValue();
      const hasNewNotifications = !collection.ids.reduce(
        (allInOldCollection, id) => allInOldCollection && activeCollection.ids.includes(id),
        true,
      );

      if (!hasNewNotifications) {
        return;
      }

      this.toastService.add({
        type: 'info',
        message: this.I18n.t('js.notifications.center.new_notifications.message'),
        link: {
          text: this.I18n.t('js.notifications.center.new_notifications.link_text'),
          target: () => {
            this.store.update({ activeCollection: collection });
            this.actions$.dispatch(centerUpdatedInPlace({ origin: this.id }));
          },
        },
      });
    });
    this.reload.next(false);
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead(action:ReturnType<typeof notificationsMarkedRead>) {
    const { activeCollection } = this.query.getValue();
    this.store.update({
      activeCollection: {
        ids: activeCollection.ids.filter((activeID) => !action.notifications.includes(activeID)),
      },
    });

    if (!this.deviceService.isMobile && this.state.includes('**.details.*')) {
      this.showNextNotification();
    }
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

  private updateSelectedNotificationIndex() {
    this
      .query
      .notifications$
      .pipe(
        take(1),
      ).subscribe((notifications:InAppNotification[][]) => {
        for (let i = 0; i < notifications.length; ++i) {
          if (notifications[i][0]._links.resource
            && idFromLink(notifications[i][0]._links.resource.href) === this.uiRouterGlobals.params.workPackageId) {
            this.selectedNotificationIndex = i;
            return;
          }
        }
      });
  }
}
