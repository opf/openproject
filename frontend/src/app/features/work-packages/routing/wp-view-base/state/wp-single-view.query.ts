import { Query } from '@datorama/akita';
import {
  WpSingleViewState,
  WpSingleViewStore,
} from './wp-single-view.store';
import {
  filter,
  map,
} from 'rxjs/operators';
import { selectCollectionAsEntities$ } from 'core-app/core/state/collection-store';
import { InAppNotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { combineLatest } from 'rxjs';

export class WpSingleViewQuery extends Query<WpSingleViewState> {
  selectNotifications$ = combineLatest([
    this.select((state) => state.notifications.filters),
    this.resourceService.query.select(),
  ]).pipe(
    filter((filters) => filters.length > 0),
    map(([filters]) => selectCollectionAsEntities$<InAppNotification>(this.resourceService, { filters })),
  );

  selectNotificationsCount$ = this
    .selectNotifications$
    .pipe(
      map((notifications) => notifications.length),
    );

  hasNotifications$ = this
    .selectNotificationsCount$
    .pipe(
      map((count) => count > 0),
    );

  get params():ApiV3ListParameters {
    return { filters: this.getValue().notifications.filters };
  }

  constructor(
    protected store:WpSingleViewStore,
    protected resourceService:InAppNotificationsResourceService,
  ) {
    super(store);
  }
}
