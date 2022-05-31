// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';
import { IStorage } from 'core-app/core/state/storages/storage.model';
import { StoragesStore } from 'core-app/core/state/storages/storages.store';
import { StoragesQuery } from 'core-app/core/state/storages/storages.query';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Injectable()
export class StoragesResourceService {
  protected store = new StoragesStore();

  protected readonly query = new StoragesQuery(this.store);

  private get storagesPath():string {
    return `${this.apiV3Service.root.path}/storages`;
  }

  constructor(
    private readonly http:HttpClient,
    private readonly toastService:ToastService,
    private readonly apiV3Service:ApiV3Service,
  ) {}

  lookup(link:IHalResourceLink, require = false):Observable<IStorage> {
    const id = idFromLink(link.href);

    if (require && !this.query.hasEntity(id)) {
      return this.http
        .get<IStorage>(`${this.storagesPath}/${id}`)
        .pipe(
          tap((storage) => {
            if (storage) {
              this.store.add(storage);
            }
          }),
          catchError((error) => {
            this.toastService.addError(error);
            throw error;
          }),
        );
    }

    return this.query.selectEntity(id)
      .pipe(
        map((storage) => {
          if (!storage) {
            throw new Error('not found');
          }
          return storage;
        }),
      );
  }
}
