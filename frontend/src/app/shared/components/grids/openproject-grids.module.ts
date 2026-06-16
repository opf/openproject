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

import { CUSTOM_ELEMENTS_SCHEMA, NgModule } from '@angular/core';
import { DynamicModule } from 'ng-dynamic-component';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { OpenprojectCalendarModule } from 'core-app/features/calendar/openproject-calendar.module';
import { FormsModule } from '@angular/forms';
import { DragDropModule } from '@angular/cdk/drag-drop';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { WidgetWpCalendarComponent } from 'core-app/shared/components/grids/widgets/wp-calendar/wp-calendar.component';
import {
  WidgetTimeEntriesCurrentUserComponent,
} from 'core-app/shared/components/grids/widgets/time-entries/current-user/time-entries-current-user.component';
import { GridWidgetsService } from 'core-app/shared/components/grids/widgets/widgets.service';
import { GridComponent } from 'core-app/shared/components/grids/grid/grid.component';
import { AddGridWidgetModalComponent } from 'core-app/shared/components/grids/widgets/add/add.modal';
import { WidgetDocumentsComponent } from 'core-app/shared/components/grids/widgets/documents/documents.component';
import { WidgetNewsComponent } from 'core-app/shared/components/grids/widgets/news/news.component';
import { WidgetWpTableComponent } from 'core-app/shared/components/grids/widgets/wp-table/wp-table.component';
import { WidgetMenuComponent } from 'core-app/shared/components/grids/widgets/menu/widget-menu.component';
import { WidgetWpTableMenuComponent } from 'core-app/shared/components/grids/widgets/wp-table/wp-table-menu.component';
import { GridInitializationService } from 'core-app/shared/components/grids/grid/initialization.service';
import { WidgetWpGraphComponent } from 'core-app/shared/components/grids/widgets/wp-graph/wp-graph.component';
import { WidgetWpGraphMenuComponent } from 'core-app/shared/components/grids/widgets/wp-graph/wp-graph-menu.component';
import {
  WidgetWpTableQuerySpaceComponent,
} from 'core-app/shared/components/grids/widgets/wp-table/wp-table-qs.component';
import {
  OpenprojectWorkPackageGraphsModule,
} from 'core-app/shared/components/work-package-graphs/openproject-work-package-graphs.module';
import {
  WidgetProjectDescriptionComponent,
} from 'core-app/shared/components/grids/widgets/project-description/project-description.component';
import { WidgetHeaderComponent } from 'core-app/shared/components/grids/widgets/header/header.component';
import { WidgetWpOverviewComponent } from 'core-app/shared/components/grids/widgets/wp-overview/wp-overview.component';
import { WidgetCustomTextComponent } from 'core-app/shared/components/grids/widgets/custom-text/custom-text.component';
import { OpenprojectFieldsModule } from 'core-app/shared/components/fields/openproject-fields.module';
import {
  WidgetTimeEntriesProjectComponent,
} from 'core-app/shared/components/grids/widgets/time-entries/project/time-entries-project.component';
import { WidgetSubprojectsComponent } from 'core-app/shared/components/grids/widgets/subprojects/subprojects.component';
import { OpenprojectAttachmentsModule } from 'core-app/shared/components/attachments/openproject-attachments.module';
import { WidgetMembersComponent } from 'core-app/shared/components/grids/widgets/members/members.component';
import {
  WidgetProjectStatusComponent,
} from 'core-app/shared/components/grids/widgets/project-status/project-status.component';
import { OpenprojectTimeEntriesModule } from 'core-app/shared/components/time_entries/openproject-time-entries.module';
import {
  WidgetTimeEntriesCurrentUserMenuComponent,
} from 'core-app/shared/components/grids/widgets/time-entries/current-user/time-entries-current-user-menu.component';
import {
  TimeEntriesCurrentUserConfigurationModalComponent,
} from './widgets/time-entries/current-user/configuration-modal/configuration.modal';
import {
  WidgetFavoriteProjectsComponent,
} from 'core-app/shared/components/grids/widgets/favorite-projects/widget-favorite-projects.component';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpenprojectEnterpriseModule } from 'core-app/features/enterprise/openproject-enterprise.module';
import { ErrorBlankSlateComponent } from './widgets/error-blankslate/error-blankslate.component';

@NgModule({
  imports: [
    FormsModule,
    DragDropModule,

    OpSharedModule,
    OpenprojectModalModule,
    OpenprojectWorkPackagesModule,
    OpenprojectWorkPackageGraphsModule,
    OpenprojectCalendarModule,
    OpenprojectTimeEntriesModule,
    OpenprojectEnterpriseModule,

    OpenprojectAttachmentsModule,

    DynamicModule,

    // Support for inline editig fields
    OpenprojectFieldsModule,
    IconModule,

    ErrorBlankSlateComponent,
  ],
  providers: [
    GridWidgetsService,
    GridInitializationService,
  ],
  declarations: [
    GridComponent,

    // Widgets
    WidgetCustomTextComponent,
    WidgetDocumentsComponent,
    WidgetMembersComponent,
    WidgetNewsComponent,
    WidgetWpCalendarComponent,
    WidgetWpOverviewComponent,
    WidgetWpTableComponent,
    WidgetWpTableQuerySpaceComponent,
    WidgetWpGraphComponent,
    WidgetProjectDescriptionComponent,
    WidgetProjectStatusComponent,
    WidgetSubprojectsComponent,
    WidgetFavoriteProjectsComponent,
    WidgetTimeEntriesCurrentUserComponent,
    WidgetTimeEntriesProjectComponent,

    // Widget menus
    WidgetMenuComponent,
    WidgetWpTableMenuComponent,
    WidgetWpGraphMenuComponent,
    WidgetTimeEntriesCurrentUserMenuComponent,
    TimeEntriesCurrentUserConfigurationModalComponent,

    AddGridWidgetModalComponent,

    WidgetHeaderComponent,
  ],
  exports: [
    GridComponent,
  ],
  schemas: [CUSTOM_ELEMENTS_SCHEMA]
})
export class OpenprojectGridsModule {
}
