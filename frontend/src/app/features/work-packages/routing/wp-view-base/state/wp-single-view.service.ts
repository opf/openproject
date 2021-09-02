import { Injectable } from '@angular/core';
import { WpSingleViewStore } from './wp-single-view.store';
import { WpSingleViewQuery } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.query';
import { take } from 'rxjs/operators';
import { selectCollectionAsHrefs$ } from 'core-app/core/state/collection-store';
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

  readonly query = new WpSingleViewQuery(this.store, this.ianService);

  constructor(
    readonly actions$:ActionsService,
    private ianService:InAppNotificationsService,
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

    this.reload();
  }

  markAllAsRead():void {
    selectCollectionAsHrefs$(this.ianService, { filters: this.store.getValue().notifications.filters })
      .pipe(
        take(1),
      )
      .subscribe((collection) => {
        this.actions$.dispatch(
          markNotificationsAsRead({ caller: this, notifications: collection.ids }),
        );
      });
  }

  private reload() {
    this
      .ianService
      .fetchNotifications(this.query.params)
      .subscribe();
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead() {
    this.reload();
  }
}
