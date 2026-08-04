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
import { PrimaryRenderPass, RowRenderInfo } from '../primary-render-pass';
import { TimelineRowBuilder } from './timeline-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';

export class TimelineRenderPass {
  /** Row builders */
  protected timelineBuilder:TimelineRowBuilder;

  /** Resulting timeline body */
  public timelineBody:DocumentFragment;

  constructor(public readonly injector:Injector,
    private table:WorkPackageTable,
    private tablePass:PrimaryRenderPass) {
  }

  public render() {
    // Prepare and reset the render pass
    this.timelineBody = document.createDocumentFragment();
    this.timelineBuilder = new TimelineRowBuilder(this.injector, this.table);

    // Render into timeline fragment
    this.tablePass.renderedOrder.forEach((row:RowRenderInfo) => {
      const wpId = row.workPackage ? row.workPackage.id : null;

      const secondary = this.timelineBuilder.build(wpId);
      secondary.classList.add(row.classIdentifier, `${row.classIdentifier}-timeline`, ...row.additionalClasses);
      this.timelineBody.appendChild(secondary);
    });
  }
}
