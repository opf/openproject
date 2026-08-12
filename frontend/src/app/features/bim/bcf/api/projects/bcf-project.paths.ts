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

import { BcfResourcePath } from 'core-app/features/bim/bcf/api/bcf-path-resources';
import { BcfApiRequestService } from 'core-app/features/bim/bcf/api/bcf-api-request.service';
import { BcfProjectResource } from 'core-app/features/bim/bcf/api/projects/bcf-project.resource';
import { HTTPClientHeaders, HTTPClientParamMap } from 'core-app/features/hal/http/http.interfaces';
import { BcfTopicCollectionPath } from 'core-app/features/bim/bcf/api/topics/bcf-viewpoint-collection.paths';
import { BcfExtensionPaths } from 'core-app/features/bim/bcf/api/extensions/bcf-extension.paths';

export class BcfProjectPaths extends BcfResourcePath {
  readonly bcfProjectService = new BcfApiRequestService(this.injector, BcfProjectResource);

  /** /topics */
  public readonly topics = new BcfTopicCollectionPath(this.injector, this.path, 'topics');

  public readonly extensions = new BcfExtensionPaths(this.injector, this.path, 'extensions');

  get(params:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}) {
    return this.bcfProjectService.get(this.toPath(), params, headers);
  }
}
