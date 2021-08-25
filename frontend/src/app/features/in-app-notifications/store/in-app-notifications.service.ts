import { Injectable } from '@angular/core';
import {
  debounceTime,
  map,
  switchMap,
  take,
  tap,
} from 'rxjs/operators';
import { applyTransaction, ID, setLoading } from '@datorama/akita';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { NotificationsService } from 'core-app/shared/components/notifications/notifications.service';
import { InAppNotificationsQuery } from 'core-app/features/in-app-notifications/store/in-app-notifications.query';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { InAppNotificationsStore } from './in-app-notifications.store';
import { InAppNotification, NOTIFICATIONS_MAX_SIZE } from './in-app-notification.model';
import { Observable } from 'rxjs';
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
      .pipe(debounceTime(0))
      .subscribe(() => {
        this.fetchNotifications();
        this.fetchCount();
      });
  }

  fetchNotifications():Observable<IHALCollection<InAppNotification>> {
    this.store.setLoading(true);

    const { activeFacet, activeFilters } = this.query.getValue();

    const call = this
      .apiV3Service
      .notifications
      .facet(activeFacet, {
        pageSize: NOTIFICATIONS_MAX_SIZE,
        filters: activeFilters,
      });

    call
      .pipe(
        tap((events) => this.sideLoadInvolvedWorkPackages(events._embedded.elements)),
      )
      .subscribe(
        (events) => applyTransaction(() => {
          this.store.set(events._embedded.elements);
          this.store.update({ notShowing: events.total - events.count });
        }),
        (error) => this.notifications.addError(error),
      )
      .add(() => this.store.setLoading(false));

    return call;
  }

  fetchCount():Observable<number> {
    const { activeFilters } = this.query.getValue();

    return this
      .apiV3Service
      .notifications
      .unread({ pageSize: 0, filters: activeFilters })
      .pipe(
        map((events) => events.total),
        tap((unreadCount) => {
          this.store.update({ unreadCount });
        }),
      );
  }

  update(id:ID, inAppNotification:Partial<InAppNotification>):void {
    this.store.update(id, inAppNotification);
  }

  setActiveFacet(facet:string):void {
    this.store.update((state) => ({ ...state, activeFacet: facet }));
  }

  setActiveFilters(filters:ApiV3ListFilter[]):void {
    this.store.update((state) => ({ ...state, activeFilters: filters }));
  }

  markAllRead() {
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

  markAsRead(notifications:InAppNotification[], keep = false) {
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

  private sideLoadInvolvedWorkPackages(elements:InAppNotification[]) {
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
