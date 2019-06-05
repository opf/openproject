import {Injectable} from '@angular/core';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
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
import {input, InputState, multiInput, MultiInputState, State} from 'reactivestates';
import {States} from '../states.service';
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {StateCacheService} from "core-components/states/state-cache.service";

@Injectable()
export class FormsCacheService extends StateCacheService<FormResource> {

  private $formCache = multiInput<FormResource>();

  constructor(private readonly halResourceService:HalResourceService) {
    super();
  }

  protected load(href:string):Promise<FormResource> {
    return this.halResourceService
      .post<FormResource>(href, {})
      .toPromise();
  }

  protected loadAll(ids:string[]):Promise<undefined> {
    return Promise
      .all(ids.map(id => this.load(id)))
      .then(_ => undefined);
  }

  protected get multiState():MultiInputState<FormResource> {
    return this.$formCache;
  }
}
