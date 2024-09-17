//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, Injector } from '@angular/core';
import { debounceTime, defaultIfEmpty, distinctUntilChanged, map, mapTo, switchMap, take, tap } from 'rxjs/operators';
import { forkJoin, from, Observable, Subject } from 'rxjs';
import { ID, Query } from '@datorama/akita';
import { StateService } from '@uirouter/angular';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IToast, ToastService } from 'core-app/shared/components/toaster/toast.service';
import {
  centerUpdatedInPlace,
  markNotificationsAsRead,
  notificationCountIncreased,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { EffectCallback, EffectHandler } from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import {
  InAppNotificationsResourceService,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { mapHALCollectionToIDCollection } from 'core-app/core/state/resource-store';
import {
  IAN_FACET_FILTERS,
  IanCenterStore,
  InAppNotificationFacet,
} from 'core-app/features/in-app-notifications/center/state/ian-center.store';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { DeviceService } from 'core-app/core/browser/device.service';
import { ApiV3ListFilter, ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { FrameElement } from '@hotwired/turbo';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';

export interface INotificationPageQueryParameters {
  filter?:string|null;
  name?:string|null;
}

@Injectable({ providedIn: 'root' })
@EffectHandler
export class IanCenterService extends UntilDestroyedMixin {
  readonly id = 'ian-center';

  readonly store = new IanCenterStore();

  readonly query = new Query(this.store);

  activeFacet$ = this.query.select('activeFacet');

  notLoaded$ = this.query.select('notLoaded');

  activeCollection$ = this.query.select('activeCollection');

  menuFrame = document.getElementById('notifications_sidemenu') as FrameElement;

  loading$:Observable<boolean> = this.query.selectLoading();

  selectNotifications$:Observable<INotification[]> = this
    .activeCollection$
    .pipe(
      switchMap((collection) => {
        const lookupId = (id:ID) => this.resourceService.lookup(id).pipe(take(1));
        return forkJoin(collection.ids.map(lookupId))
          .pipe(defaultIfEmpty([]));
      }),
    );

  aggregatedCenterNotifications$ = this
    .selectNotifications$
    .pipe(
      map((notifications) => (
        _.groupBy(notifications, (notification) => notification._links.resource?.href || 'none')
      )),
      distinctUntilChanged(),
    );

  notifications$ = this
    .aggregatedCenterNotifications$
    .pipe(
      map((items) => Object.values(items)),
      distinctUntilChanged(),
    );

  hasNotifications$ = this
    .notifications$
    .pipe(
      distinctUntilChanged(),
      map((items) => items.length > 0),
      distinctUntilChanged(),
    );

  hasMoreThanPageSize$ = this
    .notLoaded$
    .pipe(
      map((notLoaded) => notLoaded > 0),
      distinctUntilChanged(),
    );

  get params():ApiV3ListParameters {
    const state = this.store.getValue();
    const hasFilters = state.filters.name && state.filters.filter;
    return {
      ...state.params,
      filters: [
        ...state.activeFacet === 'all' ? IAN_FACET_FILTERS.all : IAN_FACET_FILTERS.unread,
        ...(
          hasFilters
            ? ([[state.filters.filter, '=', [state.filters.name]]] as ApiV3ListFilter[])
            : []
        ),
      ],
    };
  }

  private activeReloadToast:IToast|null = null;

  private reload = new Subject();

  private onReload = this.reload.pipe(
    debounceTime(0),
    tap((setToLoading) => {
      if (setToLoading) {
        this.store.setLoading(true);
      }
    }),
    switchMap(() => this
      .resourceService
      .fetchCollection(this.params)
      .pipe(
        switchMap(
          (results) => from(this.sideLoadInvolvedWorkPackages(results._embedded.elements))
            .pipe(
              mapTo(mapHALCollectionToIDCollection(results)),
            ),
        ),
      )),

    // We need to be slower than the onReload subscribers set below.
    // Because they're subscribers they're called next in the callback queue.
    // We need our loading state to be set to false only after all data is in the store,
    // but we cannot guarantee that here, since the data is set _after_ this piece of code
    // gets run. The solution is to queue this piece of code back, allowing the store contents
    // update before the loading state gets reset.
    tap(() => setTimeout(() => this.store.setLoading(false))),
  );

  public selectedNotificationIndex = 0;

  public selectedNotification:INotification;

  selectedWorkPackage$ = this.urlParams.pathMatching$(/\/details\/(\d+)/);

  constructor(
    readonly I18n:I18nService,
    readonly injector:Injector,
    readonly resourceService:InAppNotificationsResourceService,
    readonly actions$:ActionsService,
    readonly apiV3Service:ApiV3Service,
    readonly toastService:ToastService,
    readonly urlParams:UrlParamsService,
    readonly state:StateService,
    readonly deviceService:DeviceService,
    readonly pathHelper:PathHelperService,
  ) {
    super();
    this.reload.subscribe();

    this.selectedWorkPackage$.subscribe((id:string) => {
      this.updateSelectedNotification(id);
    });
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

    if (facet === 'unread') {
      if (this.selectedNotification?.readIAN) {
        this.goToCenter();
      }
    }
    this.reload.next(true);
  }

  markAsRead(notifications:ID[]):void {
    this.actions$.dispatch(
      markNotificationsAsRead({ origin: this.id, notifications }),
    );
  }

  openSplitScreen(workPackageId:string, tabIdentifier:string = 'activity'):void {
    const link = this.pathHelper.notificationsDetailsPath(workPackageId, tabIdentifier) + window.location.search;
    Turbo.visit(link, { frame: 'content-bodyRight', action: 'advance' });
  }

  openFullView(workPackageId:string|null):void {
    void this.state.go('work-packages.show', { workPackageId });
  }

  goToCenter():void {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-argument
    void this.state.go(this.state.current.data.baseRoute);
  }

  showNextNotification():void {
    void this
      .notifications$
      .pipe(take(1))
      .subscribe((notifications:INotification[][]) => {
        if (notifications.length <= 0) {
          window.location.href = this.pathHelper.notificationsPath();
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

      if (this.activeReloadToast) {
        this.toastService.remove(this.activeReloadToast);
        this.activeReloadToast = null;
      }

      this.activeReloadToast = this.toastService.add({
        type: 'info',
        icon: 'bell',
        message: this.I18n.t('js.notifications.center.new_notifications.message'),
        link: {
          text: this.I18n.t('js.notifications.center.new_notifications.link_text'),
          target: () => {
            this.store.update({ activeCollection: collection });
            this.actions$.dispatch(centerUpdatedInPlace({ origin: this.id }));
            this.activeReloadToast = null;
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
    if (action.all) {
      this.store.update({ activeCollection: { ids: [] }, activeFacet: 'unread' });

      // Reload the sidemenu frame
      void this.menuFrame.reload();

      return;
    }

    const { activeCollection } = this.query.getValue();
    this.store.update({
      activeCollection: {
        ids: activeCollection.ids.filter((activeID) => !action.notifications.includes(activeID)),
      },
    });

    if (!this.deviceService.isMobile && window.location.href.includes('details')) {
      this.showNextNotification();
    }

    // Reload the sidemenu frame
    void this.menuFrame.reload();
  }

  private sideLoadInvolvedWorkPackages(elements:INotification[]):Promise<unknown> {
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

  private updateSelectedNotification(selected:string) {
    void this
      .notifications$
      .pipe(
        take(1),
      )
      .subscribe(
        (notifications:INotification[][]) => {
          for (let i = 0; i < notifications.length; ++i) {
            if (notifications[i][0]._links.resource && idFromLink(notifications[i][0]._links.resource.href) === selected) {
              this.selectedNotificationIndex = i;
              [this.selectedNotification] = notifications[i];
              return;
            }
          }
        },
      );
  }
}
