import {
  Injectable,
  Injector,
} from '@angular/core';
import {
  IAN_FACET_FILTERS,
  IanCenterStore,
  InAppNotificationFacet,
} from './ian-center.store';
import {
  map,
  switchMap,
  take,
} from 'rxjs/operators';
import {
  selectCollection$,
  selectCollectionEntities$,
} from 'core-app/core/state/collection-store.type';
import { InAppNotificationsService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import {
  markNotificationsAsRead,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { InAppNotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { IanCenterQuery } from 'core-app/features/in-app-notifications/center/state/ian-center.query';
import { ID } from '@datorama/akita';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { Apiv3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { ActionsService } from 'core-app/core/state/actions/actions.service';

@Injectable()
@EffectHandler
export class IanCenterService extends UntilDestroyedMixin {
  readonly id = 'ian-center';

  readonly store = new IanCenterStore();

  readonly query = new IanCenterQuery(this.store, this.ianService);

  activeFacet$ = this.query.select('activeFacet');

  notLoaded$ = this.query.select('notLoaded');

  paramsChanges$ = this
    .query
    .select(['params', 'activeFacet']);

  selectCollection$ = this
    .paramsChanges$
    .pipe(
      switchMap(() => selectCollection$(this.ianService, this.params)),
    );

  selectNotifications$ = this
    .paramsChanges$
    .pipe(
      switchMap(() => selectCollectionEntities$<InAppNotification>(this.ianService, this.params)),
    );

  aggregatedCenterNotifications$ = this
    .selectNotifications$
    .pipe(
      map((notifications) => (
        _.groupBy(notifications, (notification) => notification._links.resource?.href || 'none')
      )),
    );

  constructor(
    readonly injector:Injector,
    readonly ianService:InAppNotificationsService,
    readonly actions$:ActionsService,
  ) {
    super();
  }

  setFacet(facet:InAppNotificationFacet):void {
    this.store.update({ activeFacet: facet });
    this.reload();
  }

  markAsRead(notifications:ID[]):void {
    this.actions$.dispatch(
      markNotificationsAsRead({ caller: this, notifications }),
    );
  }

  markAllAsRead():void {
    selectCollection$(this.ianService, this.store.getValue().params)
      .pipe(
        take(1),
      )
      .subscribe((collection) => {
        this.markAsRead(collection.ids);
      });
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead(action:ReturnType<typeof notificationsMarkedRead>) {
    if (action.caller !== this) {
      this.reload();
    }
  }

  private reload() {
    this.ianService
      .fetchNotifications(this.params)
      .subscribe();
  }

  private get params():Apiv3ListParameters {
    const state = this.store.getValue();
    return { ...state.params, filters: IAN_FACET_FILTERS[state.activeFacet] };
  }
}
