import { Injector } from '@angular/core';
import { combineLatest, Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';

export function workPackageRelationsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const wpRelations = injector.get(WorkPackageRelationsService);
  const apiV3Service = injector.get(ApiV3Service);
  const wpId = workPackage.id!.toString();

  wpRelations.require(wpId);

  return combineLatest([
    wpRelations
      .state(wpId.toString())
      .values$(),
    apiV3Service
      .work_packages
      .id(wpId)
      .requireAndStream(),
  ])
    .pipe(
      map(([relations, workPackage]) => {
        const relationCount = _.size(relations);
        const childrenCount = _.size(workPackage.children);

        return relationCount + childrenCount;
      }),
    );
}
