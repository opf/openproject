import {
  IProjectAutocompleteItem,
  IProjectAutocompleteItemTree,
} from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocomplete-item';
import { Observable } from 'rxjs';
import { getPaginatedResults } from 'core-app/core/apiv3/helpers/get-paginated-results';
import { IProject } from 'core-app/core/state/projects/project.model';
import {
  ApiV3ListFilter,
  listParamsString,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { map } from 'rxjs/operators';
import { buildTree } from 'core-app/shared/components/autocompleter/project-autocompleter/insert-in-list';
import { recursiveSort } from 'core-app/shared/components/autocompleter/project-autocompleter/recursive-sort';
import { HttpClient } from '@angular/common/http';

export const loadAvailableProjects = (
  searchTerm:string,
  apiFilters:ApiV3ListFilter[],
  apiUrl:string,
  mapResultsFn:(projects:IProjectAutocompleteItem[]) => IProjectAutocompleteItem[] = (projects) => projects,
  http:HttpClient,
):Observable<IProjectAutocompleteItemTree[]> => {
  return getPaginatedResults<IProject>(
    (params) => {
      const filters:ApiV3ListFilter[] = [...apiFilters];

      if (searchTerm.length) {
        filters.push(['name_and_identifier', '~', [searchTerm]]);
      }

      const url = new URL(apiUrl, window.location.origin);
      const fullParams = {
        filters,
        select: [
          'elements/id',
          'elements/name',
          'elements/identifier',
          'elements/self',
          'elements/ancestors',
          'total',
          'count',
          'pageSize',
        ],
        ...params,
      };
      const collectionURL = `${listParamsString(fullParams)}&${url.searchParams.toString()}`;
      url.searchParams.forEach((key) => url.searchParams.delete(key));
      return http.get<IHALCollection<IProject>>(url.toString() + collectionURL);
    },
  )
    .pipe(
      map((projects) => projects.map((project) => ({
        id: project.id,
        href: project._links.self.href,
        name: project.name,
        disabled: false,
        ancestors: project._links.ancestors,
        children: [],
      }))),
      map(mapResultsFn),
      map((projects) => projects.sort((a, b) => a.ancestors.length - b.ancestors.length)),
      map((projects) => buildTree(projects)),
      map((projects) => recursiveSort(projects)),
    );
};
