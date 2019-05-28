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
import {MultiInputState} from "reactivestates";
import {Injectable} from '@angular/core';
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {StateCacheService} from 'core-components/states/state-cache.service';
import {UserDmService} from 'core-app/modules/hal/dm-services/user-dm.service';
import {States} from 'core-components/states.service';
import {StatusDmService} from "core-app/modules/hal/dm-services/status-dm.service";
import {StatusResource} from "core-app/modules/hal/resources/status-resource";
import {VersionResource} from "core-app/modules/hal/resources/version-resource";
import {VersionDmService} from "core-app/modules/hal/dm-services/version-dm.service";

@Injectable()
export class VersionCacheService extends StateCacheService<VersionResource>  {

  constructor(readonly states:States,
              readonly versionDm:VersionDmService) {
    super();
  }

  protected load(id:number|string):Promise<VersionResource> {
    return this.versionDm.one(id);
  }

  protected loadAll(ids:string[]):Promise<unknown> {
    return this.versionDm.list();
  }

  protected get multiState():MultiInputState<VersionResource> {
    return this.states.versions;
  }
}
