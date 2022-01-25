import { Query } from '@datorama/akita';
import { combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';
import { IProject } from 'core-app/core/state/projects/project.model';
import { collectionKey } from 'core-app/core/state/collection-store';
import {
  IanMenuState,
  IanMenuStore,
} from './ian-menu.store';

export class IanMenuQuery extends Query<IanMenuState> {
  projectsFilter$ = this.select('projectsFilter');

  projectsForNotifications$ = combineLatest([
    this.projectsFilter$,
    this.projectsResourceService.query.select(),
  ]).pipe(
    map(([filterParams, collectionData]) => {
      const key = collectionKey(filterParams);
      const collection = collectionData.collections[key];
      const ids = collection?.ids || [];

      return ids
        .map((id:string) => this.projectsResourceService.query.getEntity(id))
        .filter((item:IProject|undefined) => !!item) as IProject[];
    }),
  );

  notificationsByProject$ = combineLatest([
    this.select('notificationsByProject'),
    this.projectsForNotifications$,
  ]).pipe(
    map(([notifications, projects]) => notifications.map((notification) => {
      const project = projects.find((p) => p.id.toString() === idFromLink(notification._links.valueLink[0].href));
      return {
        ...notification,
        projectHasParent: !!project?._links.parent.href,
      };
    })),
  );

  notificationsByReason$ = this.select('notificationsByReason');

  constructor(
    protected store:IanMenuStore,
    protected resourceService:InAppNotificationsResourceService,
    protected projectsResourceService:ProjectsResourceService,
  ) {
    super(store);
  }
}
