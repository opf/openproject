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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3DayPaths } from 'core-app/core/apiv3/endpoints/days/api-v3-day-paths';
import { IDay } from 'core-app/core/state/days/day.model';
import {
  ApiV3GettableResource,
  ApiV3ResourceCollection,
} from 'core-app/core/apiv3/paths/apiv3-resource';

export class ApiV3DaysPaths extends ApiV3ResourceCollection<IDay, ApiV3DayPaths> {
  // Base path
  public readonly path:string;

  constructor(readonly apiRoot:ApiV3Service,
    protected basePath:string) {
    super(apiRoot, basePath, 'days', ApiV3DayPaths);
  }

  // Static paths

  // /api/v3/days/week
  public readonly week = new ApiV3ResourceCollection<IDay, ApiV3DayPaths>(this.apiRoot, this.path, 'week');

  // /api/v3/days/nonWorkingDays
  public readonly nonWorkingDays = new ApiV3ResourceCollection<IDay, ApiV3DayPaths>(this.apiRoot, this.path, 'non_working');
}
