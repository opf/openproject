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

import { input } from '@openproject/reactivestates';
import { Injectable } from '@angular/core';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

@Injectable()
export class BoardFiltersService {
  /**
   * We need to remember the current filter, that may either come
   * from the saved board, or were assigned by the user.
   *
   * This is due to the fact we do not work on an query object here.
   */
  filters = input<ApiV3Filter[]>([]);

  get current():ApiV3Filter[] {
    return this.filters.getValueOr([]);
  }
}
