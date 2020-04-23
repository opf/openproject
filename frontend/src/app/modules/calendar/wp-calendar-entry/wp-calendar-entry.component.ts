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

import {Component, ViewChild} from '@angular/core';
import {WorkPackagesViewBase} from "core-app/modules/work_packages/routing/wp-view-base/work-packages-view.base";
import {WorkPackagesCalendarController} from "core-app/modules/calendar/wp-calendar/wp-calendar.component";

@Component({
  templateUrl: './wp-calendar-entry.component.html'
})

export class WorkPackagesCalendarEntryComponent extends WorkPackagesViewBase {
  @ViewChild(WorkPackagesCalendarController, { static: true }) calendarElement:WorkPackagesCalendarController;

  protected set loadingIndicator(promise:Promise<unknown>) {
    this.loadingIndicatorService.indicator('calendar-entry').promise = promise;
  }

  public refresh(visibly:boolean, firstPage:boolean):Promise<unknown> {
    return this.loadingIndicator =
      this.wpListService.loadCurrentQueryFromParams(this.projectIdentifier!);
  }
}
