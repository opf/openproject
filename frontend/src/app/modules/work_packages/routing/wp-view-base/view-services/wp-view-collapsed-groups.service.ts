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

import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageViewBaseService} from './wp-view-base.service';
import {Injectable} from '@angular/core';

@Injectable()
export class WorkPackageViewCollapsedGroupsService extends WorkPackageViewBaseService<{ [identifier:string]:boolean }> {
  valueFromQuery(query:QueryResource) {
    return {};
  }

  public collapseAll() {
    this.setCollapsedAll(true);
  }

  public expandAll() {
    this.setCollapsedAll(false);
  }

  public setCollapsedAll(collapsed:boolean) {
    let newState:{ [identifier:string]:boolean } = {};

    this.querySpace.groups.value!.forEach((group) => {
      newState[group.identifier] = collapsed;
    });

    this.update(newState);
    this.querySpace.collapsedGroups.putValue(newState);
  }
}
