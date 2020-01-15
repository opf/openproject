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
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {HttpClient} from "@angular/common/http";

export type QueryOrder = { [wpId:string]:number };

@Injectable()
export class QueryOrderDmService {
  constructor(protected http:HttpClient,
              protected pathHelper:PathHelperService) {
  }

  public get(id:string):Promise<QueryOrder> {
    return this.http
      .get<QueryOrder>(
        this.orderPath(id)
      )
      .toPromise()
      .then(result => result || {});
  }

  public update(id:string, delta:QueryOrder):Promise<string> {
    return this.http
      .patch(
        this.orderPath(id),
        { delta: delta },
        { withCredentials: true }
      )
      .toPromise()
      .then((response:{t:string}) => response.t);
  }

  public delete(id:string, ...wpIds:string[]) {
    let delta:QueryOrder = {}
    wpIds.forEach(id => delta[id] = -1);

    return this.update(id, delta);
  }

  protected orderPath(id:string) {
    return this.pathHelper.api.v3.queries.id(id).order.toString();
  }
}
