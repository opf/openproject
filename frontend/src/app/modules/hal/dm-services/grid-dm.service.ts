//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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

import {Injectable} from '@angular/core';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {AbstractDmService} from "core-app/modules/hal/dm-services/abstract-dm.service";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {HalPayloadHelper} from "core-app/modules/hal/schemas/hal-payload.helper";

@Injectable()
export class GridDmService extends AbstractDmService<GridResource> {
  constructor(protected halResourceService:HalResourceService,
              protected pathHelper:PathHelperService,
              protected apiV3Service:APIV3Service) {
    super(halResourceService,
          pathHelper,
          apiV3Service);
  }

  public createForm(resource:GridResource|null|any = null, schema:SchemaResource|null = null) {
    let payload = this.extractPayload(resource, schema);

    return this.halResourceService.post<FormResource>(this.apiV3Service.grids.form.path,
                                                      payload).toPromise();
  }

  public create(resource:GridResource, schema:SchemaResource|null = null):Promise<GridResource> {
    let payload = this.extractPayload(resource, schema);

    return this.halResourceService.post<GridResource>(this.apiV3Service.grids.path,
                                                      payload).toPromise();
  }

  public update(resource:GridResource, schema:SchemaResource|null = null):Promise<GridResource> {
    let payload = this.extractPayload(resource, schema);

    return this.halResourceService.patch<GridResource>(this.apiV3Service.grids.id(resource.id!).toString(),
                                                       payload).toPromise();
  }

  public updateForm(resource:GridResource, schema:SchemaResource|null = null) {
    let payload = this.extractPayload(resource, schema);

    return this.halResourceService.post<FormResource>(this.apiV3Service.grids.id(resource.idFromLink).form.toString(),
                                                      payload).toPromise();
  }

  public extractPayload(resource:GridResource|null = null, schema:SchemaResource|null = null) {
    if (resource && schema) {
      let payload = HalPayloadHelper.extractPayloadFromSchema(resource, schema);

      // The widget only states the type of the widget resource but does not explain
      // the widget itself. We therefore have to do that by hand.
      if (payload.widgets) {
        payload.widgets = resource.widgets.map((widget) => {
          return {
            id: widget.id,
            startRow: widget.startRow,
            endRow: widget.endRow,
            startColumn: widget.startColumn,
            endColumn: widget.endColumn,
            identifier: widget.identifier,
            options: widget.options
          };
        });
      }

      return payload;
    } else if (!(resource instanceof HalResource)) {
      return resource;
    } else {
      return {};
    }
  }

  protected listUrl() {
    return this.apiV3Service.grids.toString();
  }

  protected oneUrl(id:number|string) {
    return this.apiV3Service.grids.id(id).toString();
  }
}
