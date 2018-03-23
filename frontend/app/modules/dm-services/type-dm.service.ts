//-- copyright
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
//++

import {HalRequestService} from 'core-app/modules/hal/services/hal-request.service';
import {Inject, Injectable} from '@angular/core';
import {v3PathToken} from 'core-app/angular4-transition-utils';
import {RootResource} from 'core-app/modules/hal/resources/root-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {TypeResource} from 'core-app/modules/hal/resources/type-resource';
import {States} from 'core-components/states.service';

@Injectable()
export class TypeDmService {
  constructor(protected halRequest:HalRequestService,
              protected states:States,
              @Inject(v3PathToken) protected v3Path:any) {
  }

  public loadAll():Promise<TypeResource[]> {
    const typeUrl = this.v3Path.types();

    return this.halRequest
      .get<CollectionResource<TypeResource>>(typeUrl)
      .toPromise()
      .then((result:CollectionResource<TypeResource>) => {
        // TODO move into a TypeCacheService
        _.each(result.elements, (type) => this.states.types.get(type.href!).putValue(type));
        return result.elements;
      });
  }

  public load():Promise<RootResource> {
    return this.halRequest
      .get<RootResource>(this.v3Path.root())
      .toPromise();
  }
}
