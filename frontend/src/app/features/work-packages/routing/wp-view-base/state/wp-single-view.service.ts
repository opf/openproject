import {
  Injectable,
  Injector,
} from '@angular/core';
import { WpSingleViewStore } from './wp-single-view.store';
import { WpSingleViewQuery } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.query';
import {
  filter,
  map,
  switchMap,
  take,
} from 'rxjs/operators';
import {
  selectCollection$,
  selectCollectionEntities$,
} from 'core-app/core/state/collection-store.type';
import { InAppNotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { InAppNotificationsService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  markNotificationsAsRead,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';

@EffectHandler
@Injectable()
export class WpSingleViewService extends UntilDestroyedMixin {
  id = 'WorkPackage Activity Store';

  protected store = new WpSingleViewStore();

  readonly query = new WpSingleViewQuery(this.store);

  selectNotifications$ = this
    .query
    .select((state) => state.notifications.filters)
    .pipe(
      filter((filters) => filters.length > 0),
      switchMap((filters) => selectCollectionEntities$<InAppNotification>(this.ianService, { filters })),
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

  constructor(
    readonly injector:Injector,
    private ianService:InAppNotificationsService,
    private actions$:ActionsService,
  ) {
    super();
  }

  setFilters(workPackageId:string):void {
    const filters:ApiV3ListFilter[] = [
      ['readIAN', '=', false],
      ['resourceId', '=', [workPackageId]],
      ['resourceType', '=', ['WorkPackage']],
    ];

    this.store.update(({ notifications }) => (
      {
        notifications: {
          ...notifications,
          filters,
        },
      }
    ));

    this.reload(filters);
  }

  markAllAsRead():void {
    selectCollection$(this.ianService, { filters: this.store.getValue().notifications.filters })
      .pipe(
        take(1),
      )
      .subscribe((collection) => {
        this.actions$.dispatch(
          markNotificationsAsRead({ caller: this, notifications: collection.ids }),
        );
      });
  }

  private reload(filters:ApiV3ListFilter[]) {
    this
      .ianService
      .fetchNotifications({ filters })
      .subscribe();
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead(action:ReturnType<typeof notificationsMarkedRead>) {
    if (action.caller !== this) {
      const { filters } = this.store.getValue().notifications;
      this.reload(filters);
    }
  }
}
