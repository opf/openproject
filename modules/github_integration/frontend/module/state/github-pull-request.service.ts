// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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

import { Injectable } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { Observable } from 'rxjs';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import {
  CollectionStore,
  ResourceCollectionLoadOptions,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';
import { IGithubPullRequest } from 'core-app/features/plugins/linked/openproject-github_integration/state/github-pull-request.model';
import { GithubPullRequestsStore } from 'core-app/features/plugins/linked/openproject-github_integration/state/github-pull-request.store';
import { ID } from '@datorama/akita';

@Injectable()
export class GithubPullRequestResourceService extends ResourceCollectionService<IGithubPullRequest> {
  ofWorkPackage(workPackage:WorkPackageResource) {
    return this.requireEntity(`${workPackage.href as string}/github_pull_requests`);
  }

  requireSingle(id:ID) {
    return this.requireEntity(this.entityPath(id));
  }

  fetchCollection(
    params:ApiV3ListParameters|string,
    options:ResourceCollectionLoadOptions = { handleErrors: true },
  ):Observable<IHALCollection<IGithubPullRequest>> {
    if (typeof params !== 'string') {
      throw new Error('Github PR service can only deal with string collection keys being their full paths')
    }

    return this.request(params, params, options);
  }

  protected basePath():string {
    return this.apiV3Service.github_pull_requests.path;
  }

  protected entityPath(id:ID) {
    return this.apiV3Service.github_pull_requests.id(id).path;
  }

  protected createStore():CollectionStore<IGithubPullRequest> {
    return new GithubPullRequestsStore();
  }
}
