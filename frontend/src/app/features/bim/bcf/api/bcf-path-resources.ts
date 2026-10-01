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

import { Injector } from '@angular/core';
import { Constructor } from 'core-app/core/util-types';
import { SimpleResource, SimpleResourceCollection } from 'core-app/core/apiv3/paths/path-resources';

export class BcfResourcePath extends SimpleResource {
  constructor(readonly injector:Injector,
    basePath:string,
    readonly id:string|number) {
    super(basePath, id);
  }
}

export class BcfResourceCollectionPath<T extends BcfResourcePath> extends SimpleResourceCollection<T> {
  constructor(readonly injector:Injector,
    protected basePath:string,
    segment:string,
    protected resource?:Constructor<T>) {
    super(basePath, segment, resource);
  }

  public id(id:string|number):T {
    return new (this.resource || BcfResourcePath)(this.injector, this.path, id) as T;
  }
}
