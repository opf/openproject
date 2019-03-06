// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {OpenprojectCommonModule} from 'core-app/modules/common/openproject-common.module';
import {NgModule} from '@angular/core';
import {FullCalendarModule} from 'ng-fullcalendar';
import {WorkPackagesCalendarEntryComponent} from "core-app/modules/calendar/wp-calendar-entry/wp-calendar-entry.component";
import {WorkPackagesEmbeddedCalendarEntryComponent} from "core-app/modules/calendar/wp-embedded-calendar/wp-embedded-calendar-entry.component";
import {WorkPackagesCalendarController} from "core-app/modules/calendar/wp-calendar/wp-calendar.component";
import {OpenprojectWorkPackagesModule} from "core-app/modules/work_packages/openproject-work-packages.module";
import {Ng2StateDeclaration, UIRouterModule} from "@uirouter/angular";

require("fullcalendar/dist/locale-all.js");

export const CALENDAR_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'work-packages.calendar',
    url: '/calendar',
    component: WorkPackagesCalendarEntryComponent,
    reloadOnSearch: false,
    data: {
      parent: 'work-packages'
    }
  }
];

@NgModule({
  imports: [
    // Commons
    OpenprojectCommonModule,

    // Routes for /work_packages/calendar
    UIRouterModule.forChild({ states: CALENDAR_ROUTES }),

    // Work Package module
    OpenprojectWorkPackagesModule,

    // Calendar component
    FullCalendarModule,
  ],
  declarations: [
    // Work package calendars
    WorkPackagesCalendarEntryComponent,
    WorkPackagesCalendarController,
    WorkPackagesEmbeddedCalendarEntryComponent,
  ],
  entryComponents: [
    WorkPackagesEmbeddedCalendarEntryComponent,
    WorkPackagesCalendarController,
    WorkPackagesCalendarEntryComponent,
  ],
  exports: [
    WorkPackagesCalendarController
  ]
})
export class OpenprojectCalendarModule {
}
