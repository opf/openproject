//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { APIv3GettableResource, APIv3ResourceCollection } from "core-app/modules/apiv3/paths/apiv3-resource";
import { GridResource } from "core-app/modules/hal/resources/grid-resource";
import { APIv3FormResource } from "core-app/modules/apiv3/forms/apiv3-form-resource";
import { ConfigurationResource } from "core-app/modules/hal/resources/configuration-resource";
import { Observable } from "rxjs";
import { shareReplay } from "rxjs/operators";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

export class Apiv3ConfigurationPath extends APIv3GettableResource<ConfigurationResource> {
  private $configuration:Observable<ConfigurationResource>;

  constructor(protected apiRoot:APIV3Service,
              readonly basePath:string) {
    super(apiRoot, basePath, 'configuration');
  }



  public get():Observable<ConfigurationResource> {
    if (this.$configuration) {
      return this.$configuration;
    }

    return this.$configuration = this.halResourceService
      .get<ConfigurationResource>(this.path)
      .pipe(
        shareReplay()
      );
  }
}
