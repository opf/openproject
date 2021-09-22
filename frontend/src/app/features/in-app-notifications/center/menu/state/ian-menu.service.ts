import {
  Injectable,
  Injector,
} from '@angular/core';
import { switchMap } from 'rxjs/operators';
import {
  markNotificationsAsRead,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';
import { IanMenuQuery } from './ian-menu.query';
import {
  IanMenuStore,
  IAN_MENU_PROJECT_FILTERS,
  IAN_MENU_REASON_FILTERS,
} from './ian-menu.store';

@Injectable()
@EffectHandler
export class IanMenuService {
  readonly id = 'ian-center';

  readonly store = new IanMenuStore();

  readonly query = new IanMenuQuery(this.store, this.ianResourceService, this.projectsResourceService);

  constructor(
    readonly injector:Injector,
    readonly ianResourceService:InAppNotificationsResourceService,
    readonly projectsResourceService:ProjectsResourceService,
    readonly actions$:ActionsService,
    readonly apiV3Service:APIV3Service,
  ) {
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead() {
    return this.reload();
  }

  public reload() {
    this.ianResourceService.fetchNotifications(IAN_MENU_PROJECT_FILTERS)
      .subscribe((data) => {
        this.store.update({ notificationsByProject: data.groups });
        this.projectsResourceService.fetchProjects({
          pageSize: 100,
          filters: [['id', '=', data.groups!.map(group => idFromLink(group._links.valueLink[0].href))]],
        }).subscribe();
      });
    this.ianResourceService.fetchNotifications(IAN_MENU_REASON_FILTERS)
      .subscribe((data) => this.store.update({ notificationsByReason: data.groups }));
  }
}
