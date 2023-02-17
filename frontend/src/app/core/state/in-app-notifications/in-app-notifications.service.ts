import { Injectable } from '@angular/core';
import { tap } from 'rxjs/operators';
import { Observable } from 'rxjs';
import { ID } from '@datorama/akita';
import {
  markNotificationsAsRead,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { EffectCallback, EffectHandler } from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { InAppNotificationsStore } from './in-app-notifications.store';
import { INotification } from './in-app-notification.model';
import { CollectionStore, ResourceCollectionService } from 'core-app/core/state/resource-collection.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

@EffectHandler
@Injectable()
export class InAppNotificationsResourceService extends ResourceCollectionService<INotification> {
  @InjectField() actions$:ActionsService;

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

  protected basePath():string {
    return this
      .apiV3Service
      .notifications
      .path;
  }
}
