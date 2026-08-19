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

import { BcfResourceCollectionPath, BcfResourcePath } from 'core-app/features/bim/bcf/api/bcf-path-resources';
import { BcfTopicResource } from 'core-app/features/bim/bcf/api/topics/bcf-topic.resource';
import { BcfApiRequestService } from 'core-app/features/bim/bcf/api/bcf-api-request.service';
import { BcfViewpointPaths } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint.paths';
import { BcfViewpointCollectionPath } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint-collection.paths';
import { HTTPClientHeaders, HTTPClientParamMap } from 'core-app/features/hal/http/http.interfaces';
import { Observable } from 'rxjs';

export class BcfTopicPaths extends BcfResourcePath {
  readonly bcfTopicService = new BcfApiRequestService(this.injector, BcfTopicResource);

  /** /comments */
  public readonly comments = new BcfResourceCollectionPath(this.injector, this.path, 'comments');

  /** /viewpoints */
  public readonly viewpoints = new BcfViewpointCollectionPath(this.injector, this.path, 'viewpoints', BcfViewpointPaths);

  get(params:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}):Observable<BcfTopicResource> {
    return this.bcfTopicService.get(this.toPath(), params, headers);
  }
}
