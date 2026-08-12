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

import { Injectable, inject } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';

@Injectable()
export class WorkPackageCardViewService {
  readonly querySpace = inject(IsolatedQuerySpace);


  public classIdentifier(wp:WorkPackageResource) {
    // The same class names are used for the proximity to the table representation.
    return `wp-row-${wp.id}`;
  }

  public get renderedCards():RenderedWorkPackage[] {
    return this.querySpace.tableRendered.getValueOr([]);
  }

  public findRenderedCard(classIdentifier:string):number {
    const index = this.renderedCards.findIndex((card) => card.classIdentifier === classIdentifier);

    return index;
  }

  public updateRenderedCardsValues(workPackages:WorkPackageResource[]) {
    this.querySpace.tableRendered.putValue(
      workPackages.map((wp) => ({
        classIdentifier: this.classIdentifier(wp),
        workPackageId: wp.id,
        hidden: false,
      })),
    );
  }
}
