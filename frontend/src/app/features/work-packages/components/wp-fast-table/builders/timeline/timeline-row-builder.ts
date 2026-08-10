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

import { Injector } from '@angular/core';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { commonRowClassName } from '../rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';

export const timelineCellClassName = 'wp-timeline-cell';

export class TimelineRowBuilder {
  @LazyInject() public states:States;

  @LazyInject() public wpTableTimeline:WorkPackageViewTimelineService;

  constructor(public readonly injector:Injector,
    protected workPackageTable:WorkPackageTable) {
  }

  public build(workPackageId:string|null) {
    const cell = document.createElement('div');
    cell.classList.add(timelineCellClassName, commonRowClassName);

    if (workPackageId) {
      cell.dataset.workPackageId = workPackageId;
    }

    return cell;
  }

  /**
   * Build and insert a timeline row for the given work package using the additional classes.
   * @param workPackage
   * @param timelineBody
   * @param rowClasses
   */
  public insert(workPackageId:string|null,
    timelineBody:DocumentFragment|HTMLElement,
    rowClasses:string[] = []) {
    const cell = this.build(workPackageId);
    cell.classList.add(...rowClasses);

    timelineBody.appendChild(cell);
  }
}
