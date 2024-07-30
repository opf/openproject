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

import { Injector } from '@angular/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { HttpClient } from '@angular/common/http';
import { SimpleResource } from 'core-app/core/apiv3/paths/path-resources';

export type QueryOrder = { [wpId:string]:number };

export class ApiV3QueryOrder extends SimpleResource {
  @InjectField() http:HttpClient;

  constructor(readonly injector:Injector,
    readonly basePath:string,
    readonly id:string|number) {
    super(basePath, id);
  }

  public get():Promise<QueryOrder> {
    return this.http
      .get<QueryOrder>(
      this.path,
    )
      .toPromise()
      .then((result) => result || {});
  }

  public update(delta:QueryOrder):Promise<string> {
    return this.http
      .patch(
        this.path,
        { delta },
        { withCredentials: true },
      )
      .toPromise()
      .then((response:{ t:string }) => response.t);
  }

  public delete(id:string, ...wpIds:string[]) {
    const delta:QueryOrder = {};
    wpIds.forEach((id) => delta[id] = -1);

    return this.update(delta);
  }
}
