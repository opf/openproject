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

import { ScrollingModule } from '@angular/cdk/scrolling';
import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import {
  InAppNotificationBellComponent,
} from 'core-app/features/in-app-notifications/bell/in-app-notification-bell.component';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import {
  InAppNotificationCenterComponent,
} from 'core-app/features/in-app-notifications/center/in-app-notification-center.component';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import {
  InAppNotificationEntryComponent,
} from 'core-app/features/in-app-notifications/entry/in-app-notification-entry.component';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import {
  OpenprojectContentLoaderModule,
} from 'core-app/shared/components/op-content-loader/openproject-content-loader.module';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { DynamicModule } from 'ng-dynamic-component';
import { InAppNotificationActorsLineComponent } from './entry/actors-line/in-app-notification-actors-line.component';
import { InAppNotificationDateAlertComponent } from './entry/date-alert/in-app-notification-date-alert.component';
import { InAppNotificationRelativeTimeComponent } from './entry/relative-time/in-app-notification-relative-time.component';
import { InAppNotificationReminderAlertComponent } from './entry/reminder-alert/in-app-notification-reminder-alert.component';
import { InAppNotificationStatusComponent } from './entry/status/in-app-notification-status.component';

@NgModule({
  declarations: [
    InAppNotificationBellComponent,
    InAppNotificationCenterComponent,
    InAppNotificationEntryComponent,
    InAppNotificationStatusComponent,
    InAppNotificationActorsLineComponent,
    InAppNotificationDateAlertComponent,
    InAppNotificationRelativeTimeComponent,
    InAppNotificationReminderAlertComponent,
  ],
  imports: [
    OpSharedModule,
    DynamicModule,
    CommonModule,
    IconModule,
    OpenprojectPrincipalRenderingModule,
    OpenprojectWorkPackagesModule,
    OpenprojectContentLoaderModule,
    ScrollingModule,
  ],
  providers: [
    IanBellService,
    IanCenterService,
  ],
})
export class OpenProjectInAppNotificationsModule {
}
