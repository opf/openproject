import { Injector } from '@angular/core';
import { Observable, combineLatest, from } from 'rxjs';
import { switchMap, startWith, filter, throttleTime, tap } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';

export function workPackageRelationsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const pathHelper = injector.get(PathHelperService);
  const wpRelations = injector.get(WorkPackageRelationsService);
  const halEvents = injector.get(HalEventsService);
  const wpId = workPackage.id!.toString();
  // It is an intermediate solution, until the API can return all relations
  // in the long term, the tabs are going to be the same as in the notifications
  const url = pathHelper.workPackageGetRelationsCounterPath(wpId.toString());

  const relationEventUpdates$ = halEvents
    .events$
    .pipe(
      filter((event) => event.resourceType === 'WorkPackage' && event.eventType === 'association' && event.id === wpId),
      tap((event) => {
        // eslint-disable-next-line no-console
        console.log('Event received:', { event, wpId });
      }),
    );

  // Listen for relation state changes
  const relationsState$ = wpRelations.state(wpId).values$();

  return combineLatest([
    // combineLatest only emits when all observables emit at least once, so we
    // add an initial null value to the stream to trigger it the first time.
    relationsState$.pipe(startWith(null)),
    relationEventUpdates$.pipe(startWith(null)),
  ]).pipe(
    // Fire directly, then ignore events for 500ms and fire again if an event was received during this time (leading: true)
    // see https://stackoverflow.com/a/57097217/177665
    throttleTime(500, undefined, { leading: true, trailing: true }),
    switchMap(() =>
      from(
        fetch(url)
          .then((res):Promise<{ count:number }> => res.json())
          .then((data) => data.count),
      )),
  );
}
