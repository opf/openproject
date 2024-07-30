//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Observable } from 'rxjs';
import { ApiV3WorkPackagePaths } from 'core-app/core/apiv3/endpoints/work_packages/api-v3-work-package-paths';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { ApiV3WorkPackageForm } from 'core-app/core/apiv3/endpoints/work_packages/apiv3-work-package-form';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3Collection } from 'core-app/core/apiv3/cache/cachable-apiv3-collection';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { WorkPackageCache } from 'core-app/core/apiv3/endpoints/work_packages/work-package.cache';
import { ApiV3GettableResource } from 'core-app/core/apiv3/paths/apiv3-resource';
import { ApiV3WorkPackageCachedSubresource } from 'core-app/core/apiv3/endpoints/work_packages/api-v3-work-package-cached-subresource';
import {
  ApiV3FilterBuilder,
  ApiV3FilterValueType,
  ApiV3Filter,
} from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

export class ApiV3WorkPackagesPaths extends ApiV3Collection<WorkPackageResource, ApiV3WorkPackagePaths, WorkPackageCache> {
  // Base path
  public readonly path:string;

  constructor(readonly apiRoot:ApiV3Service,
    protected basePath:string) {
    super(apiRoot, basePath, 'work_packages', ApiV3WorkPackagePaths);
  }

  // Static paths

  // /api/v3/(projects/:projectIdentifier)/work_packages/form
  public readonly form:ApiV3WorkPackageForm = this.subResource('form', ApiV3WorkPackageForm);

  /**
   *
   * Load a collection of work packages and put them all into cache
   *
   * @param ids
   */
  public requireAll(ids:string[]):Promise<unknown> {
    if (ids.length === 0) {
      return Promise.resolve();
    }

    return new Promise<undefined>((resolve, reject) => {
      this
        .loadCollectionsFor(_.uniq(ids))
        .then((pagedResults:WorkPackageCollectionResource[]) => {
          _.each(pagedResults, (results) => {
            if (results.schemas) {
              _.each(results.schemas.elements, (schema:SchemaResource) => {
                this.states.schemas.get(schema.href as string).putValue(schema);
              });
            }

            if (results.elements) {
              this.cache.updateWorkPackageList(results.elements);
            }
          });

          resolve(undefined);
        }, reject);
    });
  }

  /**
   * Create a work package from a form payload
   *
   * @param payload
   * @return {Promise<WorkPackageResource>}
   */
  public post(payload:object):Observable<WorkPackageResource> {
    return this
      .halResourceService
      .post<WorkPackageResource>(this.path, payload)
      .pipe(
        this.cacheResponse(),
      );
  }

  filtered<R = ApiV3GettableResource<WorkPackageCollectionResource>>(filters:ApiV3FilterBuilder, params:{ [p:string]:string } = {}):R {
    return super.filtered(filters, params, ApiV3WorkPackageCachedSubresource) as any;
  }

  /**
   * Shortcut to filter work packages by subject or ID
   * @param term
   * @param idOnly
   * @param additionalParams Additional set of params to the API
   */
  public filterByTypeaheadOrId(term:string, idOnly = false, additionalParams:{ [key:string]:string } = {}):ApiV3WorkPackageCachedSubresource {
    const filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

    if (idOnly) {
      filters.add('id', '=', [term]);
    } else {
      filters.add('typeahead', '**', [term]);
    }

    const params = {
      sortBy: '[["updatedAt","desc"]]',
      offset: '1',
      pageSize: '10',
      ...additionalParams,
    };

    return this.filtered(filters, params);
  }

  /**
   * Returns work packages within the ids array to be updated since <timestamp>
   * @param ids work package IDs to filter for
   * @param timestamp The timestamp to clip at
   */
  public filterUpdatedSince(ids:(string|null)[], timestamp:ApiV3FilterValueType):ApiV3WorkPackageCachedSubresource {
    const filters = new ApiV3FilterBuilder()
      .add('id', '=', (ids.filter((n) => n) as string[]))
      .add('updatedAt', '<>d', [timestamp, '']);

    const params = {
      offset: '1',
      pageSize: '10',
    };

    return this.filtered(filters, params);
  }

  /**
   * Loads the work packages collection for the given work package IDs.
   * Returns a WP Collection with schemas and results embedded.
   *
   * @param ids
   * @return {WorkPackageCollectionResource[]}
   */
  protected loadCollectionsFor(ids:string[]):Promise<WorkPackageCollectionResource[]> {
    return this
      .halResourceService
      .getAllPaginated(
        this.path,
        {
          filters: ApiV3Filter('id', '=', ids).toJson(),
          valid_subset: true,
        },
      )
      .toPromise() as Promise<WorkPackageCollectionResource[]>;
  }

  protected createCache():WorkPackageCache {
    return new WorkPackageCache(this.injector, this.states.workPackages);
  }

  // /api/v3/(?:projectPath)/work_packages/(:workPackageId)/available_projects
  public readonly available_projects = this.subResource('available_projects');
}
