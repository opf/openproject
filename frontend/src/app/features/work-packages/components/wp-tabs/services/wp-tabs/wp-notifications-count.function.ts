import { Injector } from '@angular/core';
import { combineLatest, Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { InAppNotificationsService } from 'core-app/core/in-app-notifications/store/in-app-notifications.service';

export function workPackageNotificationsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const ianService = injector.get(InAppNotificationsService);
  const wpId = workPackage.id!.toString();

  return ianService.get();
}
