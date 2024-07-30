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

import { ApiV3GettableResource, ApiV3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { forkJoin, from, Observable } from 'rxjs';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { map } from 'rxjs/operators';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

export const MAGIC_RELATION_SIZE = 100;

export class ApiV3RelationsPaths extends ApiV3ResourceCollection<RelationResource, ApiV3GettableResource<RelationResource>> {
  constructor(protected apiRoot:ApiV3Service,
    protected basePath:string) {
    super(apiRoot, basePath, 'relations');
  }

  /**
   * Get all versions
   */
  public get():Observable<CollectionResource<RelationResource>> {
    return this
      .halResourceService
      .get<CollectionResource<RelationResource>>(this.path);
  }

  public loadInvolved(workPackageIds:string[]):Observable<RelationResource[]> {
    if (workPackageIds.length > MAGIC_RELATION_SIZE) {
      const chunks = _.chunk(workPackageIds, MAGIC_RELATION_SIZE);
      return forkJoin(chunks.map((chunk) => this.loadInvolved(chunk)))
        .pipe(
          map((results) => _.flatten(results)),
        );
    }

    const validIds = _.filter(workPackageIds, (id) => /\d+/.test(id));

    if (validIds.length === 0) {
      return from([]);
    }

    return this
      .filtered(
        ApiV3Filter('involved', '=', validIds),
      )
      .getPaginatedResults();
  }
}
