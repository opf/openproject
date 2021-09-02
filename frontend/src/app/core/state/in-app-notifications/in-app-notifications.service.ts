import { Injectable } from '@angular/core';
import {
  catchError,
  tap,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import {
  applyTransaction,
  ID,
} from '@datorama/akita';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { NotificationsService } from 'core-app/shared/components/notifications/notifications.service';
import { InAppNotificationsStore } from './in-app-notifications.store';
import { InAppNotification } from './in-app-notification.model';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { HttpClient } from '@angular/common/http';
import { InAppNotificationsQuery } from 'core-app/core/state/in-app-notifications/in-app-notifications.query';
import { Apiv3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { collectionKey } from 'core-app/core/state/collection-store';
import {
  markNotificationsAsRead,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';

@EffectHandler
@Injectable()
export class InAppNotificationsService {
  protected store = new InAppNotificationsStore();

  readonly query = new InAppNotificationsQuery(this.store);

  private get notificationsPath():string {
    return this
      .apiV3Service
      .notifications
      .path;
  }

  constructor(
    readonly actions$:ActionsService,
    private http:HttpClient,
    private apiV3Service:APIV3Service,
    private notifications:NotificationsService,
  ) {
  }

  fetchNotifications(params:Apiv3ListParameters):Observable<IHALCollection<InAppNotification>> {
    const collectionURL = collectionKey(params);

    return this
      .http
      .get<IHALCollection<InAppNotification>>(this.notificationsPath + collectionURL)
      .pipe(
        tap((events) => {
          applyTransaction(() => {
            this.store.add(events._embedded.elements);
            this.store.update(({ collections }) => (
              {
                collections: {
                  ...collections,
                  [collectionURL]: {
                    ids: events._embedded.elements.map((el) => el.id),
                  },
                },
              }
            ));
          });
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

  modifyCollection(params:Apiv3ListParameters, callback:(collection:ID[]) => ID[]):void {
    const key = collectionKey(params);
    this.store.update(({ collections }) => (
      {
        collections: {
          ...collections,
          [key]: {
            ...collections[key],
            ids: [...callback(collections[key]?.ids || [])],
          },
        },
      }
    ));
  }

  removeFromCollection(params:Apiv3ListParameters, ids:ID[]):void {
    const key = collectionKey(params);
    this.store.update(({ collections }) => (
      {
        collections: {
          ...collections,
          [key]: {
            ...collections[key],
            ids: (collections[key]?.ids || []).filter((id) => !ids.includes(id)),
          },
        },
      }
    ));
  }

  markAsRead(notifications:ID[]):Observable<unknown> {
    return this
      .apiV3Service
      .notifications
      .markRead(notifications)
      .pipe(
        tap(() => {
          this.store.update(notifications, { readIAN: true });
        }),
      );
  }

  /**
   * Mark the given notification IDs as read through the API.
   */
  @EffectCallback(markNotificationsAsRead)
  private markNotificationsAsRead(action:ReturnType<typeof markNotificationsAsRead>) {
    this
      .markAsRead(action.notifications)
      .subscribe(() => (
        this.actions$.dispatch(notificationsMarkedRead(action))
      ));
  }
}
