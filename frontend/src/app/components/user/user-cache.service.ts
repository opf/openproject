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
import {MultiInputState} from "reactivestates";
import {Injectable} from '@angular/core';
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {StateCacheService} from 'core-components/states/state-cache.service';
import {UserDmService} from 'core-app/modules/hal/dm-services/user-dm.service';
import {States} from 'core-components/states.service';

@Injectable({ providedIn: 'root' })
export class UserCacheService extends StateCacheService<UserResource>  {

  constructor(readonly states:States,
              readonly userDmService:UserDmService) {
    super();
  }

  protected load(id:number|string):Promise<UserResource> {
    return this.userDmService.load(id);
  }

  protected loadAll(ids:string[]):Promise<undefined> {
    const promises = ids.map(id => this.load(id));
    return Promise.all(promises).then(() => undefined);
  }

  protected get multiState():MultiInputState<UserResource> {
    return this.states.users;
  }
}
