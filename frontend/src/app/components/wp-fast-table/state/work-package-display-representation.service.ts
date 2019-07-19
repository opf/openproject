// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageQueryStateService} from './wp-table-base.service';
import {States} from 'core-components/states.service';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Injectable} from '@angular/core';
import {InputState} from "reactivestates";
import {QuerySortByResource} from "core-app/modules/hal/resources/query-sort-by-resource";

export const wpDisplayListRepresentation:string = 'list';
export const wpDisplayCardRepresentation:string = 'card';

@Injectable()
export class WorkPackageDisplayRepresentationService extends WorkPackageQueryStateService<string> {
  public constructor(readonly states:States,
                     readonly querySpace:IsolatedQuerySpace) {
    super(querySpace);
  }

  public get state():InputState<string> {
    return this.querySpace.displayRepresentation;
  }

  public hasChanged(query:QueryResource) {
    return this.current !== query.displayRepresentation;
  }

  valueFromQuery(query:QueryResource) {
    return query.displayRepresentation || wpDisplayListRepresentation;
  }

  public applyToQuery(query:QueryResource) {
    query.displayRepresentation = this.current;
    return true;
  }

  public get current():string {
    return this.state.getValueOr(wpDisplayListRepresentation);
  }

  public setDisplayRepresentation(representation:string) {
    this.update(representation);
  }
}
