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

import { OpSharedModule } from 'core-app/shared/shared.module';
import { NgModule } from '@angular/core';
import { ReactiveFormsModule } from '@angular/forms';
import { FullCalendarModule } from '@fullcalendar/angular';
import { WorkPackagesCalendarComponent } from 'core-app/features/calendar/wp-calendar/wp-calendar.component';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { UIRouterModule } from '@uirouter/angular';
import { TimeEntryCalendarComponent } from 'core-app/features/calendar/te-calendar/te-calendar.component';
import { OpenprojectFieldsModule } from 'core-app/shared/components/fields/openproject-fields.module';
import { OpenprojectTimeEntriesModule } from 'core-app/shared/components/time_entries/openproject-time-entries.module';
import { WorkPackagesCalendarPageComponent } from 'core-app/features/calendar/wp-calendar-page/wp-calendar-page.component';
import { CALENDAR_ROUTES } from 'core-app/features/calendar/calendar.routes';
import { QueryGetIcalUrlModalComponent } from 'core-app/shared/components/modals/get-ical-url-modal/query-get-ical-url.modal';

@NgModule({
  imports: [
    // Commons
    OpSharedModule,

    // Routes for /calendar
    UIRouterModule.forChild({ states: CALENDAR_ROUTES }),

    // Work Package module
    OpenprojectWorkPackagesModule,

    // Time entry module
    OpenprojectTimeEntriesModule,

    // Editable fields e.g. for modals
    OpenprojectFieldsModule,

    // Calendar component
    FullCalendarModule,

    // Angular reactive forms, required for QueryGetIcalUrlModalComponent
    ReactiveFormsModule,
  ],
  declarations: [
    // Work package calendars
    WorkPackagesCalendarPageComponent,
    WorkPackagesCalendarComponent,
    TimeEntryCalendarComponent,
    QueryGetIcalUrlModalComponent,
  ],
  exports: [
    WorkPackagesCalendarComponent,
    TimeEntryCalendarComponent,
  ],
})
export class OpenprojectCalendarModule {
}
