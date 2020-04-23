// -- copyright
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
// ++

import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageQueryStateService} from './wp-view-base.service';
import {States} from 'core-components/states.service';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Injectable} from '@angular/core';


export const wpDisplayListRepresentation = 'list';
export const wpDisplayCardRepresentation = 'card';
export type WorkPackageDisplayRepresentationValue = 'list'|'card';

@Injectable()
export class WorkPackageViewDisplayRepresentationService extends WorkPackageQueryStateService<string|null> {
  public constructor(readonly states:States,
                     readonly querySpace:IsolatedQuerySpace) {
    super(querySpace);
  }

  public hasChanged(query:QueryResource) {
    return this.current !== query.displayRepresentation;
  }

  valueFromQuery(query:QueryResource) {
    return query.displayRepresentation || null;
  }

  public applyToQuery(query:QueryResource) {
    const current = this.current;
    query.displayRepresentation = current === null ? undefined : current;

    return false;
  }

  public get current():string|null {
    return this.lastUpdatedState.getValueOr(null);
  }

  public get isList():boolean {
    const current = this.current;
    return !current || current === wpDisplayListRepresentation;
  }

  public get isCards():boolean {
    return this.current === wpDisplayCardRepresentation;
  }

  public setDisplayRepresentation(representation:WorkPackageDisplayRepresentationValue) {
    this.update(representation);
  }
}
