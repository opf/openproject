import { Injector } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { NOTIFICATIONS_MAX_SIZE } from 'core-app/features/in-app-notifications/store/in-app-notification.model';
import { InAppNotificationsService } from 'core-app/features/in-app-notifications/store/in-app-notifications.service';

export function workPackageNotificationsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const ianService = injector.get(InAppNotificationsService);

  return ianService.query.unread$
    .pipe(
      map((data) => data.length),
    );
}
