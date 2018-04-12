//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {input} from 'reactivestates';
import {distinctUntilChanged, filter} from 'rxjs/operators';
import {Injectable} from '@angular/core';

export type QueryMenuEvent = {
  event:'add' | 'remove' | 'rename';
  queryId:string;
  path?:string;
  label?:string;
};

@Injectable()
export class QueryMenuService {
  private events = input<QueryMenuEvent>();

  /**
   * Add a query menu item
   */
  public add(name:string, path:string, queryId:string) {
    this.events.putValue({event: 'add', queryId: queryId, path: path, label: name});
  }

  public rename(queryId:string, name:string) {
    this.events.putValue({event: 'rename', queryId: queryId, label: name});
  }

  public remove(queryId:string) {
    this.events.putValue({event: 'remove', queryId: queryId, label: queryId});
  }

  public on(type:string) {
    return this.events
      .values$()
      .pipe(
        filter((e:QueryMenuEvent) => e.event === type),
        distinctUntilChanged()
      );
  }
}
