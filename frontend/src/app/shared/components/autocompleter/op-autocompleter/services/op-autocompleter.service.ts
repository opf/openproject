import { Injectable, inject } from '@angular/core';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { map } from 'rxjs/operators';
import { ApiV3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { ApiV3UserPaths } from 'core-app/core/apiv3/endpoints/users/apiv3-user-paths';
import { ApiV3WorkPackagePaths } from 'core-app/core/apiv3/endpoints/work_packages/api-v3-work-package-paths';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { forkJoin, Observable, of } from 'rxjs';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  IAPIFilter,
  TOpAutocompleterResource,
} from 'core-app/shared/components/autocompleter/op-autocompleter/typings';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { ApiV3ProjectPaths } from 'core-app/core/apiv3/endpoints/projects/apiv3-project-paths';
import { addFiltersToPath } from 'core-app/core/apiv3/helpers/add-filters-to-path';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';

@Injectable({ providedIn: 'root' })
export class OpAutocompleterService extends UntilDestroyedMixin {
  private apiV3Service = inject(ApiV3Service);
  private halResourceService = inject(HalResourceService);


  // A method for fetching data with different resource type and different filter
  public loadAvailable(matching:string, resource:TOpAutocompleterResource, filters?:IAPIFilter[], searchKey?:string):Observable<HalResource[]> {
    const finalFilters:ApiV3FilterBuilder = this.createFilters(filters ?? [], matching, searchKey);
    const params = this.createParams(resource);

    const filteredData = (this.apiV3Service[resource] as
      ApiV3ResourceCollection<UserResource | WorkPackageResource, ApiV3UserPaths | ApiV3WorkPackagePaths>)
      .filtered(finalFilters, params).get()
      .pipe(map((collection) => collection.elements));
    return filteredData;
  }

  // A method for fetching the object for a provided value using the API
  public loadValue(id:string | string[], resource:TOpAutocompleterResource, multiple:boolean):Observable<HalResource | HalResource[]> {
    if (multiple) {
      const calls = (id as string[])
        .map((singleId) => this.loadSingleValue(singleId, resource));
      return forkJoin(calls);
    }

    return this.loadSingleValue(id as string, resource);
  }

  protected loadSingleValue(id:string, resource:TOpAutocompleterResource) {
    return (this.apiV3Service[resource] as
      ApiV3ResourceCollection<UserResource | WorkPackageResource | ProjectResource, ApiV3UserPaths | ApiV3WorkPackagePaths | ApiV3ProjectPaths>)
      .id(id)
      .get();
  }

  protected createParams(resource:TOpAutocompleterResource):Record<string, string> {
    if (resource === 'work_packages') {
      return {
        // Fields are listed in op-autocompleter/op-autocompleter.component.html. `_type` is the
        // HAL class discriminator: omitting it causes the factory to fall back to a generic
        // HalResource, and getters like `formattedId` on WorkPackageResource never resolve.
        select: 'elements/id,elements/displayId,elements/subject,elements/author,elements/type,elements/project,elements/status,elements/_type',
        sortBy: '[["updatedAt","desc"]]',
      };
    }

    return {};
  }

  // A method for building filters
  protected createFilters(filters:IAPIFilter[], matching:string, searchKey?:string) {
    const finalFilters = new ApiV3FilterBuilder();

    for (const filter of filters) {
      finalFilters.add(filter.name, filter.operator, filter.values);
    }
    if (matching) {
      finalFilters.add(searchKey ?? '', '**', [matching]);
    }
    return finalFilters;
  }

  // A method for returning data based on the resource type
  // If you need to fetch our default date sources like work_packages or users,
  // you should use the default method (loadAvailable), otherwise you should implement a function for
  // your desired resource
  public loadData(matching:string|null, resource:TOpAutocompleterResource, filters?:IAPIFilter[], searchKey?:string, allowEmpty = false) {
    // Exit early if the query string is empty as there is no typeahead
    if (!allowEmpty && (matching === null || matching.length === 0)) {
      return of([]);
    }

    switch (resource) {
      // in this case we can add more functions for fetching usual resources
      default: {
        return this.loadAvailable(matching ?? '', resource, filters, searchKey);
      }
    }
  }

  // A method for returning data based on a custom URL (i.e. in time logging we have a special endpoint for retrieving
  // work packages)
  public loadFromUrl(url:string, matching:string|null, resource:TOpAutocompleterResource, filters?:IAPIFilter[], searchKey?:string, allowEmpty = false) {
    // Exit early if the query string is empty as there is no typeahead
    if (!allowEmpty && (matching === null || matching.length === 0)) {
      return of([]);
    }

    const finalFilters:ApiV3FilterBuilder = this.createFilters(filters ?? [], matching ?? '', searchKey);
    const params = this.createParams(resource);

    const stringifiedBuiltOutUrl = addFiltersToPath(url, finalFilters, params).toString();

    return this.halResourceService
      .get(stringifiedBuiltOutUrl)
      .pipe(
        map((collection:CollectionResource<HalResource>) => collection.elements),
      );
  }
}
