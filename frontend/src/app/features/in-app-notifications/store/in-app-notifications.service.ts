import { Injectable } from '@angular/core';
import { applyTransaction, ID, transaction, withTransaction } from '@datorama/akita';
import { InAppNotification } from './in-app-notification.model';
import { InAppNotificationsStore } from './in-app-notifications.store';
import { forkJoin, Observable, timer } from "rxjs";
import { APIV3Service } from "core-app/core/apiv3/api-v3.service";
import { map, switchMap, tap } from "rxjs/operators";
import { NotificationsService } from "core-app/shared/components/notifications/notifications.service";
import { InAppNotificationsQuery } from "core-app/features/in-app-notifications/store/in-app-notifications.query";
import { take } from "rxjs/internal/operators/take";
import apply = Reflect.apply;

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
    this
      .apiV3Service
      .notifications
      .unread()
      .subscribe(
        events => {
          applyTransaction(() => {
            this.store.set(events._embedded.elements);
            this.store.update({ count: events.total });
          });
        },
        error => {
          this.notifications.addError(error);
        },
      )
      .add(
        () => this.store.setLoading(false)
      );
  }

  count$():Observable<number> {
    return this
      .apiV3Service
      .notifications
      .unread({ pageSize: 0 })
      .pipe(
        map(events => events.total),
        tap(count => this.store.update({ count }))
      );
  }

  @transaction()
  add(inAppNotification:InAppNotification):void {
    this.store.add(inAppNotification);
    this.store.update(state => ({ ...state, count: state.count + 1}));
  }

  update(id:ID, inAppNotification:Partial<InAppNotification>):void {
    this.store.update(id, inAppNotification);
  }

  @transaction()
  remove(id:ID):void {
    this.store.remove(id);
    this.store.update(state => ({ ...state, count: state.count + 1}));
  }

  markAllRead():void {
    this.query
      .unread$
      .pipe(
        take(1),
        switchMap(events =>
          forkJoin(
            events.map(event => this.apiV3Service.notifications.id(event.id).markRead())
          )
        )
      )
      .subscribe(() => {
        applyTransaction(() => {
          this.store.update(null, { read: true });
          this.store.update({ count: 0 });
        });
      });
  }
}
