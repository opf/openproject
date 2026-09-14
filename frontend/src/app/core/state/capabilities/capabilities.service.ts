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

import { Injectable } from '@angular/core';
import {
  catchError,
  map,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';
import { CapabilitiesStore } from 'core-app/core/state/capabilities/capabilities.store';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';

@Injectable()
export class CapabilitiesResourceService extends ResourceStoreService<ICapability> {
  /**
   * Returns the loaded capabilities for a context
   */
  public loadedCapabilities$(contextId:string):Observable<ICapability[]> {
    return this
      .query
      .selectAll()
      .pipe(
        map((capabilities) => capabilities.filter((cap) => cap._links.context.href.endsWith(`/${contextId}`))),
      );
  }

  public fetchCapabilities(params:ApiV3ListParameters):Observable<IHALCollection<ICapability>> {
    return this
      .fetchCollection(params)
      .pipe(
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

  protected createStore():ResourceStore<ICapability> {
    return new CapabilitiesStore();
  }

  protected basePath():string {
    return this.apiV3Service.capabilities.path;
  }
}
