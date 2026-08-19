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

import { HTTPClientHeaders, HTTPClientParamMap } from 'core-app/features/hal/http/http.interfaces';
import { BcfResourcePath } from 'core-app/features/bim/bcf/api/bcf-path-resources';
import { BcfApiRequestService } from 'core-app/features/bim/bcf/api/bcf-api-request.service';
import { BcfViewpointSelectionPath } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint-selection.paths';
import { Observable } from 'rxjs';
import { BcfViewpointVisibilityPaths } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint-visibility.paths';
import { BcfViewpoint } from 'core-app/features/bim/bcf/api/bcf-api.model';
import { map } from 'rxjs/operators';

export class BcfViewpointPaths extends BcfResourcePath {
  readonly bcfViewpointsService = new BcfApiRequestService<BcfViewpoint>(this.injector);

  public readonly selection = new BcfViewpointSelectionPath(this.injector, this.path, 'selection');

  public readonly visibility = new BcfViewpointVisibilityPaths(this.injector, this.path, 'visibility');

  get(params:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}):Observable<BcfViewpoint> {
    return this.bcfViewpointsService.get(this.toPath(), params, headers);
  }

  delete(headers:HTTPClientHeaders = {}):Observable<void> {
    return this.bcfViewpointsService
      .request('delete', this.toPath(), {}, headers)
      .pipe(
        map(() => { }),
      );
  }
}
