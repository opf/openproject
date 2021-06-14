import { Component, Injector, Input, OnInit } from '@angular/core';
import { combineLatest, Observable } from 'rxjs';
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { WorkPackageRelationsService } from "core-components/wp-relations/wp-relations.service";
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { map } from "rxjs/operators";

export function workPackageRelationsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const wpRelations = injector.get(WorkPackageRelationsService);
  const apiV3Service = injector.get(APIV3Service);
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
