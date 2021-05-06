import { Injector } from '@angular/core';
import { from, Observable } from 'rxjs';
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { map } from "rxjs/operators";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { WorkPackageWatchersService } from "core-components/wp-single-view-tabs/watchers-tab/wp-watchers.service";

export function workPackageWatchersCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const watcherService = injector.get(WorkPackageWatchersService);
  return from(watcherService.require(workPackage))
    .pipe(
      map((watchers:HalResource[]) => watchers.length),
    );
}
