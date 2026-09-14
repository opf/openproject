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

import { ChangeDetectionStrategy, Component } from '@angular/core';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';

/**
 * An entry component to be rendered by Rails for the plain work packages list
 * and the gantt chart list. Both share the same table/toolbar implementation
 * (WorkPackageViewPageComponent) and only differ in their URL (/work_packages
 * vs /gantt) - the query itself is loaded from the current URL's query_id/query_props,
 * so no inputs are needed here.
 */
@Component({
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  standalone: false,
  template: `
    <wp-view-page>
      <wp-list-view />
    </wp-view-page>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageViewPageEntryComponent {
  constructor() {
    document.body.classList.add('router--work-packages-partitioned-split-view', 'router--work-packages-base');
  }
}
