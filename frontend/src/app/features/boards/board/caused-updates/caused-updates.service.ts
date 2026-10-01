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

import { Injectable } from '@angular/core';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';

/**
 * The service is intended to store all the updates caused to a query by a user.
 * It is e.g. used to not update the board list when the current user moved a card within a list/query.
  */

@Injectable()
export class CausedUpdatesService {
  /** contains all the updates to the query caused by modifications of the user */
  private causedUpdates:string[] = [];

  public includes(query:QueryResource) {
    return this.causedUpdates.includes(this.cacheValue(query));
  }

  public add(query:QueryResource) {
    if (this.causedUpdates.length > 100) {
      this.causedUpdates.splice(0, 90);
    }

    this.causedUpdates.push(this.cacheValue(query));
  }

  private cacheValue(query:QueryResource) {
    return query.updatedAt + query.href;
  }
}
