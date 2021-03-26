import { Injectable } from '@angular/core';
import { ApiV3FilterBuilder, FilterOperator } from 'core-app/components/api/api-v3/api-v3-filter-builder';
import { debounceTime, distinctUntilChanged, map, switchMap } from 'rxjs/operators';
import { APIv3ResourceCollection } from 'core-app/modules/apiv3/paths/apiv3-resource';
import { UserResource } from 'core-app/modules/hal/resources/user-resource';
import { APIv3UserPaths } from 'core-app/modules/apiv3/endpoints/users/apiv3-user-paths';
import { APIV3WorkPackagePaths } from 'core-app/modules/apiv3/endpoints/work_packages/api-v3-work-package-paths';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {of, Observable} from "rxjs";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";


@Injectable()

export class OPAutocompleterService extends UntilDestroyedMixin {

  constructor(
    private apiV3Service:APIV3Service,
  ) {
    super();
  }

  public loadAvailable(matching:string, resource:res, conditions?:IAPIFilter[], searchKey?:string):Observable<HalResource[]> {

    const filters:ApiV3FilterBuilder = this.createFilters(conditions ?? [], matching, searchKey);

    if (matching === null || matching.length === 0) {
      return of([]);
    }
    const filteredData = (this.apiV3Service[resource] as
      APIv3ResourceCollection<UserResource|WorkPackageResource, APIv3UserPaths|APIV3WorkPackagePaths>)
      .filtered(filters).get()
      .pipe(map(collection => collection.elements));

    return filteredData;
  }

  protected createFilters(conditions:IAPIFilter[], matching:string, searchKey?:string) {
    const filters = new ApiV3FilterBuilder();

    for (const condition of conditions) {
      filters.add(condition.name, condition.operator, condition.values);
    }
    if (matching) {
      filters.add(searchKey ?? '', '**', [matching]);
    }
    return filters;
  }


  public loadData(matching:string,  resource:res, conditions?:IAPIFilter[], searchKey?:string) {
    switch (resource) {
      // TODO
      // case dataType.Principal : {

      //    break;
      // }
      default: {
         return this.loadAvailable(matching, resource, conditions, searchKey);
         break;
      }
   }
  }
}
