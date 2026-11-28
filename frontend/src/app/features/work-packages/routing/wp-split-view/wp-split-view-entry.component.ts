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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Component, OnDestroy, input } from '@angular/core';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';
import { stringAttribute } from 'core-app/shared/helpers/angular/attribute-inputs';

const splitViewBodyClass = 'router--work-packages-partitioned-split-view-details';

// Turbo's non-morphing body swap on a redirect-driven visit can construct the new
// instance before the old one's ngOnDestroy fires (observed ~29ms apart). Without a
// count, the late remove() from the dying instance would wipe out the class the new,
// live instance already added.
let splitViewInstanceCount = 0;

/**
 * An entry component to be rendered by Rails which opens an isolated query space
 * for the work package split view
 */
@Component({
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  template: `
    <op-wp-split-view [workPackageId]="workPackageId()"
      [activeTab]="activeTab()"
      [showTabs]="false"
      [resizerClass]="resizerClass()"
     />
  `,
  standalone: false,
})
export class WorkPackageSplitViewEntryComponent implements OnDestroy {
  readonly workPackageId = input('', { transform: stringAttribute('') });
  readonly activeTab = input('', { transform: stringAttribute('') });
  readonly resizerClass = input('', { transform: stringAttribute('') });

  constructor() {
    splitViewInstanceCount += 1;
    document.body.classList.add(splitViewBodyClass);
  }

  ngOnDestroy():void {
    splitViewInstanceCount -= 1;
    if (splitViewInstanceCount <= 0) {
      document.body.classList.remove(splitViewBodyClass);
    }
  }
}
