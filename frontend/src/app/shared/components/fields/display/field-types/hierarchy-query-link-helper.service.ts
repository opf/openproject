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

import { Injectable, inject } from '@angular/core';
import URI from 'urijs';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Injectable({ providedIn: 'root' })
export class HierarchyQueryLinkHelperService {
  private pathHelper = inject(PathHelperService);


  public addHref(link:HTMLAnchorElement, resource:HalResource):void {
    if (resource && resource.id) {
      const wpID = resource.id.toString();
      const props = {
        c: ['id', 'subject', 'type', 'status', 'estimatedTime', 'remainingTime', 'percentageDone'],
        hi: true,
        is: true,
        f: [{ n: 'parent', o: '=', v: [wpID] }],
      };
      link.href = URI(this.pathHelper.workPackagesPath(null))
        .query({ query_props: JSON.stringify(props) })
        .toString();
    }
  }
}
