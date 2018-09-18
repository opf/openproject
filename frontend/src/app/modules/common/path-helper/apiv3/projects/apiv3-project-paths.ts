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

import {SimpleResource} from 'core-app/modules/common/path-helper/apiv3/path-resources';
import {Apiv3QueriesPaths} from 'core-app/modules/common/path-helper/apiv3/queries/apiv3-queries-paths';
import {Apiv3TypesPaths} from "core-app/modules/common/path-helper/apiv3/types/apiv3-types-paths";

export class Apiv3ProjectPaths extends SimpleResource {
  // Base path
  public readonly path:string;

  constructor(projectPath:string, readonly projectId:string|number) {
    super(projectPath, projectId);
  }

  public readonly queries = new Apiv3QueriesPaths(this.path);

  public readonly types = new Apiv3TypesPaths(this.path);

  public readonly work_packages = {
    form: new SimpleResource(this.path, 'work_packages/form')
  };
}
