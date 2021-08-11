import { Injector } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { InAppNotification, NOTIFICATIONS_MAX_SIZE } from 'core-app/features/in-app-notifications/store/in-app-notification.model';

export function workPackageNotificationsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const apiV3Service = injector.get(APIV3Service);
  const wpId = workPackage.id!.toString();

  return apiV3Service
    .notifications
    .facet(
      'unread',
      {
        pageSize: NOTIFICATIONS_MAX_SIZE,
        filters: [
          [ 'resource_id', '=', [ wpId ] ],
          [ 'resource_type', '=', [ 'work_package' ] ],
        ],
      },
    )
    .pipe(
      map((data) => data._embedded.elements.length),
    );
}
