import { Injectable } from '@angular/core';
import { tap } from 'rxjs/operators';
import { Observable } from 'rxjs';
import { ID } from '@datorama/akita';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { HttpClient } from '@angular/common/http';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  collectionKey,
  insertCollectionIntoState,
} from 'core-app/core/state/collection-store';
import {
  markNotificationsAsRead,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { InAppNotificationsStore } from './in-app-notifications.store';
import { INotification } from './in-app-notification.model';
import {
  CollectionStore,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';

@EffectHandler
@Injectable()
export class InAppNotificationsResourceService extends ResourceCollectionService<INotification> {
  private get notificationsPath():string {
    return this
      .apiV3Service
      .notifications
      .path;
  }

  constructor(
    readonly actions$:ActionsService,
    private http:HttpClient,
    private apiV3Service:ApiV3Service,
    private toastService:ToastService,
  ) {
    super();
  }

  fetchNotifications(params:ApiV3ListParameters):Observable<IHALCollection<INotification>> {
    const collectionURL = collectionKey(params);

    return this
      .http
      .get<IHALCollection<INotification>>(this.notificationsPath + collectionURL)
      .pipe(
        tap((collection) => insertCollectionIntoState(this.store, collection, collectionURL)),
      );
  }

  update(id:ID, inAppNotification:Partial<INotification>):void {
    this.store.update(id, inAppNotification);
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

  protected createStore():CollectionStore<INotification> {
    return new InAppNotificationsStore();
  }
}
