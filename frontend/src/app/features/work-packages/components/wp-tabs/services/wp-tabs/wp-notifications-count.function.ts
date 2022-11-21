import { Injector } from '@angular/core';
import { Observable } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WpSingleViewService } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.service';

export function workPackageNotificationsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const storeService = injector.get(WpSingleViewService);
  return storeService.nonDateAlertNotificationsCount$;
}
