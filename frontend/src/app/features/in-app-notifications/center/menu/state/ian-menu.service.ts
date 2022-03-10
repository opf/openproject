import {
  Injectable,
  Injector,
} from '@angular/core';
import {
  notificationsMarkedRead,
  notificationCountIncreased,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
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
    readonly apiV3Service:ApiV3Service,
  ) {
  }

  /**
   * Check for updates after bell count increased
   */
  @EffectCallback(notificationCountIncreased)
  private checkForNewNotifications() {
    this.reload();
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead() {
    return this.reload();
  }

  public reload():void {
    this.ianResourceService.fetchNotifications(IAN_MENU_PROJECT_FILTERS)
      .subscribe((data) => {
        const projectsFilter:ApiV3ListParameters = {
          pageSize: 100,
          filters: [],
        };

        if (data.groups) {
          projectsFilter.filters = [['id', '=', data.groups.map((group) => idFromLink(group._links.valueLink[0].href))]];
        }

        this.store.update({
          notificationsByProject: data.groups,
          projectsFilter,
        });

        // Only request if there are any groups
        if (data.groups && data.groups.length > 0) {
          this.projectsResourceService.fetchProjects(projectsFilter).subscribe();
        }
      });
    this.ianResourceService.fetchNotifications(IAN_MENU_REASON_FILTERS)
      // eslint-disable-next-line @typescript-eslint/no-unsafe-return
      .subscribe((data) => this.store.update({ notificationsByReason: data.groups }));
  }
}
