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
import {ProjectResource} from 'core-app/modules/hal/resources/project-resource';
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {Apiv3ProjectsPaths} from "core-app/modules/common/path-helper/apiv3/projects/apiv3-projects-paths";
import {AbstractDmService} from "core-app/modules/hal/dm-services/abstract-dm.service";

@Injectable()
export class ProjectDmService extends AbstractDmService<ProjectResource> {
  public schema():Promise<SchemaResource> {
    return this.halResourceService
      .get<SchemaResource>(this.projectsPath.schema)
      .toPromise();
  }

  protected listUrl():string {
    return this.projectsPath.toString();
  }

  protected oneUrl(id:number|string):string {
    return this.projectsPath.id(id).toString();
  }

  private get projectsPath():Apiv3ProjectsPaths {
    return this.pathHelper.api.v3.projects;
  }
}
