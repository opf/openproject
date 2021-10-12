import {
  Injectable,
  Injector,
} from '@angular/core';
import {
  distinctUntilChanged,
  map,
  pluck,
  share,
  switchMap,
  take,
  tap,
} from 'rxjs/operators';
import { from } from 'rxjs';
import {
  ID,
  setLoading,
} from '@datorama/akita';
import {
  markNotificationsAsRead,
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
import { selectCollectionAsHrefs$ } from 'core-app/core/state/collection-store';
import { INotificationPageQueryParameters } from 'core-app/features/in-app-notifications/in-app-notifications.routes';
import {
  IanCenterStore,
  InAppNotificationFacet,
} from './ian-center.store';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { UIRouterGlobals } from '@uirouter/core';
import { StateService } from '@uirouter/angular';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Injectable()
@EffectHandler
export class IanCenterService extends UntilDestroyedMixin {
  readonly id = 'ian-center';

  readonly store = new IanCenterStore();

  readonly query = new IanCenterQuery(this.store, this.resourceService);

  public selectedNotificationIndex = 0;

  stateChanged$ = this.uiRouterGlobals.params$?.pipe(
    this.untilDestroyed(),
    pluck('workPackageId'),
    distinctUntilChanged(),
    tap(() => this.updateSelectedNotificationIndex()),
    map((workPackageId:string) => (workPackageId ? this.apiV3Service.work_packages.id(workPackageId).path : undefined)),
    share(),
  );

  constructor(
    readonly injector:Injector,
    readonly resourceService:InAppNotificationsResourceService,
    readonly actions$:ActionsService,
    readonly apiV3Service:APIV3Service,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly state:StateService,
  ) {
    super();
  }

  setFilters(filters:INotificationPageQueryParameters):void {
    this.store.update({ filters });
    this.debouncedReload();
  }

  setFacet(facet:InAppNotificationFacet):void {
    this.store.update({ activeFacet: facet });
    this.debouncedReload();
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
          return;
        }
        if (notifications[0][0]._links.resource || notifications[this.selectedNotificationIndex][0]._links.resource) {
          // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
          const wpId = idFromLink(notifications[this.selectedNotificationIndex >= notifications.length ? 0 : this.selectedNotificationIndex][0]._links.resource!.href);
          this.openSplitScreen(wpId);
        }
      });
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead(action:ReturnType<typeof notificationsMarkedRead>) {
    if (action.origin === this.id) {
      this
        .resourceService
        .removeFromCollection(this.query.params, action.notifications);
      this.showNextNotification();
    } else {
      this.reloadAndShowNextNotification();
    }
  }

  private debouncedReload = _.debounce(() => { this.reload().subscribe(); });

  private reloadAndShowNextNotification = _.debounce(() => {
    this.reload().subscribe(() => {
      this.showNextNotification();
    });
  });

  private reload() {
    return this.resourceService
      .fetchNotifications(this.query.params)
      .pipe(
        setLoading(this.store),
        switchMap((results) => from(this.sideLoadInvolvedWorkPackages(results._embedded.elements))),
        switchMap(() => this.query.notifications$),
        take(1),
      );
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
            && idFromLink(notifications[i][0]._links.resource!.href) === this.uiRouterGlobals.params.workPackageId) { // eslint-disable-line @typescript-eslint/no-non-null-assertion
            this.selectedNotificationIndex = i;
            return;
          }
        }
      });
  }
}
