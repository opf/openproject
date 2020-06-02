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
import {AbstractDmService} from "core-app/modules/hal/dm-services/abstract-dm.service";
import {TimeEntryResource} from "core-app/modules/hal/resources/time-entry-resource";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {PayloadDmService} from "core-app/modules/hal/dm-services/payload-dm.service";

@Injectable()
export class TimeEntryDmService extends AbstractDmService<TimeEntryResource> {
  constructor(protected halResourceService:HalResourceService,
              protected pathHelper:PathHelperService,
              protected payloadDm:PayloadDmService) {
    super(halResourceService, pathHelper);
  }

  protected listUrl() {
    return this.pathHelper.api.v3.time_entries.toString();
  }

  protected oneUrl(id:number|string) {
    return this.pathHelper.api.v3.time_entries.id(id).toString();
  }

  public update(resource:TimeEntryResource, schema:SchemaResource|null = null) {
    let payload = this.extractPayload(resource, schema);

    return this.halResourceService.patch<TimeEntryResource>(resource.updateImmediately.$link.href, payload).toPromise();
  }

  public updateForm(resource:TimeEntryResource, schema:SchemaResource|null = null) {
    let payload = this.extractPayload(resource, schema);

    return this.halResourceService.post<FormResource>(this.pathHelper.api.v3.time_entries.id(resource.idFromLink).form.toString(),
      payload).toPromise();
  }

  public createForm(payload:{}) {
    return this.halResourceService.post<FormResource>(this.pathHelper.api.v3.time_entries.form.toString(), payload).toPromise();
  }

  public create(payload:{}):Promise<TimeEntryResource> {
    return this.halResourceService
      .post<TimeEntryResource>(this.pathHelper.api.v3.time_entries.path, payload)
      .toPromise();
  }

  public delete(resource:TimeEntryResource) {
    return this.halResourceService
      .delete<TimeEntryResource>(this.pathHelper.api.v3.time_entries.id(resource.idFromLink).toString())
      .toPromise();
  }

  public extractPayload(resource:TimeEntryResource|null = null, schema:SchemaResource|null = null) {
    if (resource && schema) {
      return this.payloadDm.extract(resource, schema);
    } else if (!(resource instanceof HalResource)) {
      return resource;
    } else {
      return {};
    }
  }
}
