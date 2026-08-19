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

import { BcfResourceCollectionPath } from 'core-app/features/bim/bcf/api/bcf-path-resources';
import { BcfApiRequestService } from 'core-app/features/bim/bcf/api/bcf-api-request.service';
import { Observable } from 'rxjs';
import { BcfViewpointPaths } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint.paths';
import { CreateBcfViewpointData } from 'core-app/features/bim/bcf/api/bcf-api.model';

export class BcfViewpointCollectionPath extends BcfResourceCollectionPath<BcfViewpointPaths> {
  readonly bcfViewpointService = new BcfApiRequestService<CreateBcfViewpointData>(this.injector);

  post(viewpoint:CreateBcfViewpointData):Observable<CreateBcfViewpointData> {
    return this
      .bcfViewpointService
      .request(
        'post',
        this.toPath(),
        viewpoint,
      );
  }
}
