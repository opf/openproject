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

import {OpenprojectCommonModule} from 'core-app/modules/common/openproject-common.module';
import {NgModule} from '@angular/core';
import {FullCalendarModule} from '@fullcalendar/angular';
import {WorkPackagesCalendarEntryComponent} from "core-app/modules/calendar/wp-calendar-entry/wp-calendar-entry.component";
import {WorkPackagesCalendarController} from "core-app/modules/calendar/wp-calendar/wp-calendar.component";
import {OpenprojectWorkPackagesModule} from "core-app/modules/work_packages/openproject-work-packages.module";
import {Ng2StateDeclaration, UIRouterModule} from "@uirouter/angular";
import {TimeEntryCalendarComponent} from "core-app/modules/calendar/te-calendar/te-calendar.component";
import {OpenprojectFieldsModule} from "core-app/modules/fields/openproject-fields.module";
import {OpenprojectTimeEntriesModule} from "core-app/modules/time_entries/openproject-time-entries.module";
import {DisplayJobPageComponent} from "core-app/modules/job-status/display-job-page/display-job-page.component";
import {ApplicationBaseComponent} from "core-app/modules/router/base/application-base.component";

export const JOB_STATUS_ROUTE:Ng2StateDeclaration[] = [
  {
    name: 'job-statuses',
    url: '/job_statuses/{jobId:[a-z0-9-]+}',
    parent: 'root',
    component: DisplayJobPageComponent,
    data: {
      bodyClasses: 'router--job-statuses'
    }
  }
];

@NgModule({
  imports: [
    // Commons
    OpenprojectCommonModule,

    // Routes for /job_statuses/:uuid
    UIRouterModule.forChild({ states: JOB_STATUS_ROUTE }),

  ],
  declarations: [
    DisplayJobPageComponent
  ]
})
export class OpenProjectJobStatusModule {
}
