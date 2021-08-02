import { Injectable } from '@angular/core';
import { applyTransaction, ID } from '@datorama/akita';
import { Observable } from 'rxjs';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { map, switchMap, tap } from 'rxjs/operators';
import { NotificationsService } from 'core-app/shared/components/notifications/notifications.service';
import { InAppNotificationsQuery } from 'core-app/features/in-app-notifications/store/in-app-notifications.query';
import { take } from 'rxjs/internal/operators/take';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { InAppNotificationsStore } from './in-app-notifications.store';
import { InAppNotification, NOTIFICATIONS_MAX_SIZE } from './in-app-notification.model';

@Injectable({ providedIn: 'root' })
export class InAppNotificationsService {
  constructor(
    private store:InAppNotificationsStore,
    private query:InAppNotificationsQuery,
    private apiV3Service:APIV3Service,
    private notifications:NotificationsService,
  ) {
  }

  get():void {
    this.store.setLoading(true);

    const facet = this.query.getValue().activeFacet;

    this
      .apiV3Service
      .notifications
      .facet(facet, { pageSize: NOTIFICATIONS_MAX_SIZE })
      .pipe(
        tap((events) => this.sideLoadInvolvedWorkPackages(events._embedded.elements)),
      )
      .subscribe(
        (events) => {
          applyTransaction(() => {
            this.store.set(events._embedded.elements);
            this.store.update({ notShowing: events.total - events.count });
          });
        },
        (error) => {
          this.notifications.addError(error);
        },
      )
      .add(
        () => this.store.setLoading(false),
      );
  }

  count$():Observable<number> {
    return this
      .apiV3Service
      .notifications
      .unread({ pageSize: 0 })
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

  markAllRead():void {
    this.query
      .unread$
      .pipe(
        take(1),
        switchMap((events) => this.apiV3Service.notifications.markRead(events.map((event) => event.id))),
      )
      .subscribe(() => {
        applyTransaction(() => {
          this.store.update(null, { readIAN: true });
          this.store.update({ unreadCount: 0 });
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

  collapse(notification:InAppNotification):void {
    this.store.update(
      notification.id,
      {
        expanded: false,
      },
    );
  }

  expand(notification:InAppNotification):void {
    this.store.update(
      notification.id,
      {
        expanded: true,
      },
    );
  }

  markReadKeepAndExpanded(notification:InAppNotification):void {
    this
      .apiV3Service
      .notifications
      .id(notification.id)
      .markRead()
      .subscribe(() => {
        applyTransaction(() => {
          this.store.update(
            notification.id,
            {
              readIAN: true,
              keep: true,
            },
          );
          this.store.update(
            ({ unreadCount }) => ({ unreadCount: unreadCount - 1 }),
          );
        });
      });
  }
}
