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

import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DynamicModule } from 'ng-dynamic-component';
import { FullCalendarModule } from '@fullcalendar/angular';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { TeamPlannerComponent } from 'core-app/features/team-planner/team-planner/planner/team-planner.component';
import { AddAssigneeComponent } from 'core-app/features/team-planner/team-planner/assignee/add-assignee.component';
import { TeamPlannerPageComponent } from 'core-app/features/team-planner/team-planner/page/team-planner-page.component';
import { TeamPlannerEntryComponent } from 'core-app/features/team-planner/team-planner/team-planner-entry.component';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { AddExistingPaneComponent } from './add-work-packages/add-existing-pane.component';
import { OpenprojectContentLoaderModule } from 'core-app/shared/components/op-content-loader/openproject-content-loader.module';
import { TeamPlannerViewSelectMenuDirective } from 'core-app/features/team-planner/team-planner/view-select/view-select-menu.directive';

@NgModule({
  declarations: [
    TeamPlannerComponent,
    TeamPlannerPageComponent,
    TeamPlannerEntryComponent,
    AddAssigneeComponent,
    AddExistingPaneComponent,
    TeamPlannerViewSelectMenuDirective,
  ],
  imports: [
    OpSharedModule,
    DynamicModule,
    CommonModule,
    IconModule,
    OpenprojectPrincipalRenderingModule,
    OpenprojectWorkPackagesModule,
    FullCalendarModule,
    // Autocompleters
    OpenprojectAutocompleterModule,
    OpenprojectContentLoaderModule,
  ],
})
export class TeamPlannerModule {}
