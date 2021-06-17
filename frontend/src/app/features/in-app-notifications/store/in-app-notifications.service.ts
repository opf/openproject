import { Injectable } from '@angular/core';
import { ID } from '@datorama/akita';
import { InAppNotification } from './in-app-notification.model';
import { InAppNotificationsStore } from './in-app-notifications.store';
import { forkJoin, Observable, timer } from "rxjs";
import { APIV3Service } from "core-app/core/apiv3/api-v3.service";
import { map, switchMap } from "rxjs/operators";
import { NotificationsService } from "core-app/shared/components/notifications/notifications.service";
import { InAppNotificationsQuery } from "core-app/features/in-app-notifications/store/in-app-notifications.query";
import { take } from "rxjs/internal/operators/take";

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
      .events
      .unread()
      .subscribe(
        events => {
          this.store.set(events._embedded.elements);
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
      .events
      .unread({ pageSize: 0 })
      .pipe(
        map(events => events.total)
      );
  }

  add(inAppNotification:InAppNotification):void {
    this.store.add(inAppNotification);
  }

  update(id:ID, inAppNotification:Partial<InAppNotification>):void {
    this.store.update(id, inAppNotification);
  }

  remove(id:ID):void {
    this.store.remove(id);
  }

  markAllRead():void {
    this.query
      .unread$
      .pipe(
        take(1),
        switchMap(events =>
          forkJoin(
            events.map(event => this.apiV3Service.events.id(event.id).markRead())
          )
        )
      )
      .subscribe(() => {
        this.store.update(null, { read: true });
      });
  }
}
