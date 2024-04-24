import { Injector } from '@angular/core';
import { Observable } from 'rxjs';
import { WorkPackageWatchersService } from 'core-app/features/work-packages/components/wp-single-view-tabs/watchers-tab/wp-watchers.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { map } from 'rxjs/operators';

export function workPackageWatchersCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const watcherService = injector.get(WorkPackageWatchersService);
  return watcherService
    .requireAndStream(workPackage)
    .pipe(
      map((watchers:HalResource[]) => watchers.length),
    );
}
