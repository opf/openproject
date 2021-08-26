import { Injectable } from '@angular/core';
import {
  debounceTime,
  switchMap,
  take,
  tap,
  catchError,
} from 'rxjs/operators';
import { Subscription, Observable } from 'rxjs';
import { applyTransaction, ID, setLoading } from '@datorama/akita';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { NotificationsService } from 'core-app/shared/components/notifications/notifications.service';
import { InAppNotificationsQuery } from 'core-app/features/in-app-notifications/store/in-app-notifications.query';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { InAppNotificationsStore } from './in-app-notifications.store';
import { InAppNotification } from './in-app-notification.model';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';

@Injectable()
export class InAppNotificationsService {
  constructor(
    private store:InAppNotificationsStore,
    public query:InAppNotificationsQuery,
    private apiV3Service:APIV3Service,
    private notifications:NotificationsService,
  ) {
    this.query.activeFetchParameters$
      .pipe(
        debounceTime(0),
        switchMap(() => this.fetchNotifications()),
      ).subscribe();
  }

  fetchNotifications():Observable<IHALCollection<InAppNotification>> {
    this.store.setLoading(true);

    const {
      activeFacet,
      activeFilters,
      pageSize,
    } = this.query.getValue();

    return this
      .apiV3Service
      .notifications
      .facet(activeFacet, {
        pageSize,
        filters: activeFilters,
      })
      .pipe(
        tap((events) => {
          this.sideLoadInvolvedWorkPackages(events._embedded.elements);
          applyTransaction(() => {
            this.store.set(events._embedded.elements);
            this.store.update({ notLoaded: events.total - events.count });
          });
          this.store.setLoading(false);
        }),
        catchError((error) => {
          this.notifications.addError(error);
          throw error;
        }),
      );
  }

  update(id:ID, inAppNotification:Partial<InAppNotification>):void {
    this.store.update(id, inAppNotification);
  }

  setPageSize(pageSize:number):void {
    this.store.update((state) => ({ ...state, pageSize }));
  }

  setActiveFacet(facet:string):void {
    this.store.update((state) => ({ ...state, activeFacet: facet }));
  }

  setActiveFilters(filters:ApiV3ListFilter[]):void {
    this.store.update((state) => ({ ...state, activeFilters: filters }));
  }

  markAllRead():Subscription {
    return this.query
      .unread$
      .pipe(
        take(1),
        switchMap((events) => this.apiV3Service.notifications.markRead(events.map((event) => event.id))),
        setLoading(this.store),
      )
      .subscribe(() => {
        applyTransaction(() => {
          this.store.update(null, { readIAN: true });
          this.store.update({ unreadCount: 0 });
        });
      });
  }

  markAsRead(notifications:InAppNotification[], keep = false):Subscription {
    const ids = notifications.map((n) => n.id);

    return this
      .apiV3Service
      .notifications
      .markRead(ids)
      .pipe(
        setLoading(this.store),
      )
      .subscribe(() => {
        applyTransaction(() => {
          this.store.update(ids, { readIAN: true, keep });
          this.store.update(
            ({ unreadCount }) => ({ unreadCount: unreadCount - ids.length }),
          );
        });
      });
  }

  private sideLoadInvolvedWorkPackages(elements:InAppNotification[]):void {
    const wpIds = elements.map((element) => {
      const href = element._links.resource?.href;
      return href && HalResource.matchFromLink(href, 'work_packages');
    });

    void this
      .apiV3Service
      .work_packages
      .requireAll(_.compact(wpIds));
  }
}
