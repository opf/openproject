import { Query } from '@datorama/akita';
import {
  map,
  switchMap,
} from 'rxjs/operators';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { InAppNotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { selectCollectionAsEntities$ } from 'core-app/core/state/collection-store';
import {
  IanMenuState,
  IanMenuStore,
} from './ian-menu.store';

export class IanMenuQuery extends Query<IanMenuState> {
  notificationsByProject$ = this.select('notificationsByProject');
  notificationsByReason$ = this.select('notificationsByReason');

  constructor(
    protected store:IanMenuStore,
    protected resourceService:InAppNotificationsResourceService,
  ) {
    super(store);
  }
}
