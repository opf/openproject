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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { BcfResourceCollectionPath } from 'core-app/features/bim/bcf/api/bcf-path-resources';
import { BcfApiRequestService } from 'core-app/features/bim/bcf/api/bcf-api-request.service';
import { HTTPClientHeaders, HTTPClientParamMap } from 'core-app/features/hal/http/http.interfaces';
import { Observable } from 'rxjs';
import { BcfTopicPaths } from 'core-app/features/bim/bcf/api/topics/bcf-topic.paths';
import { Injector } from '@angular/core';
import { BcfTopicResource } from 'core-app/features/bim/bcf/api/topics/bcf-topic.resource';

export class BcfTopicCollectionPath extends BcfResourceCollectionPath<BcfTopicPaths> {
  readonly bcfTopicService = new BcfApiRequestService<BcfTopicResource>(this.injector, BcfTopicResource);

  constructor(readonly injector:Injector,
    protected basePath:string,
    segment:string) {
    super(injector, basePath, segment, BcfTopicPaths);
  }

  get(params:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}) {
    throw new Error('Not implemented');
  }

  /**
   * Create a topic from its to-be-associated work package
   */
  post(payload:any):Observable<BcfTopicResource> {
    return this
      .bcfTopicService
      .request(
        'post',
        this.toPath(),
        payload,
      );
  }
}
