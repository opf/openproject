//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { Injector, NgModule } from '@angular/core';
import { DynamicModule } from 'ng-dynamic-component';
import { HookService } from "core-app/modules/plugins/hook-service";
import { OpenprojectCommonModule } from "core-app/modules/common/openproject-common.module";
import { OpenprojectModalModule } from "core-app/modules/modal/modal.module";
import { OpenprojectCalendarModule } from "core-app/modules/calendar/openproject-calendar.module";
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { DragDropModule } from '@angular/cdk/drag-drop';
import { OpenprojectWorkPackagesModule } from "core-app/modules/work_packages/openproject-work-packages.module";
import { WidgetWpCalendarComponent } from "core-app/modules/grids/widgets/wp-calendar/wp-calendar.component.ts";
import { WidgetTimeEntriesCurrentUserComponent } from "core-app/modules/grids/widgets/time-entries/current-user/time-entries-current-user.component";
import { GridWidgetsService } from "core-app/modules/grids/widgets/widgets.service";
import { GridComponent } from "core-app/modules/grids/grid/grid.component";
import { AddGridWidgetModal } from "core-app/modules/grids/widgets/add/add.modal";
import { WidgetDocumentsComponent } from "core-app/modules/grids/widgets/documents/documents.component";
import { WidgetNewsComponent } from "core-app/modules/grids/widgets/news/news.component";
import { WidgetWpTableComponent } from "core-app/modules/grids/widgets/wp-table/wp-table.component";
import { WidgetMenuComponent } from "core-app/modules/grids/widgets/menu/widget-menu.component";
import { WidgetWpTableMenuComponent } from "core-app/modules/grids/widgets/wp-table/wp-table-menu.component";
import { GridInitializationService } from "core-app/modules/grids/grid/initialization.service";
import { WidgetWpGraphComponent } from "core-app/modules/grids/widgets/wp-graph/wp-graph.component";
import { WidgetWpGraphMenuComponent } from "core-app/modules/grids/widgets/wp-graph/wp-graph-menu.component";
import { WidgetWpTableQuerySpaceComponent } from "core-app/modules/grids/widgets/wp-table/wp-table-qs.component";
import { OpenprojectWorkPackageGraphsModule } from "core-app/modules/work-package-graphs/openproject-work-package-graphs.module";
import { ApiV3FilterBuilder } from "core-components/api/api-v3/api-v3-filter-builder";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { WidgetProjectDescriptionComponent } from "core-app/modules/grids/widgets/project-description/project-description.component";
import { WidgetHeaderComponent } from "core-app/modules/grids/widgets/header/header.component";
import { WidgetWpOverviewComponent } from "core-app/modules/grids/widgets/wp-overview/wp-overview.component";
import { WidgetCustomTextComponent } from "core-app/modules/grids/widgets/custom-text/custom-text.component";
import { OpenprojectFieldsModule } from "core-app/modules/fields/openproject-fields.module";
import { WidgetProjectDetailsComponent } from "core-app/modules/grids/widgets/project-details/project-details.component";
import { WidgetTimeEntriesProjectComponent } from "core-app/modules/grids/widgets/time-entries/project/time-entries-project.component";
import { WidgetSubprojectsComponent } from "core-app/modules/grids/widgets/subprojects/subprojects.component";
import { OpenprojectAttachmentsModule } from "core-app/modules/attachments/openproject-attachments.module";
import { WidgetMembersComponent } from "core-app/modules/grids/widgets/members/members.component";
import { WidgetProjectStatusComponent } from "core-app/modules/grids/widgets/project-status/project-status.component";
import { OpenprojectTimeEntriesModule } from "core-app/modules/time_entries/openproject-time-entries.module";
import { WidgetTimeEntriesCurrentUserMenuComponent } from "core-app/modules/grids/widgets/time-entries/current-user/time-entries-current-user-menu.component";
import { TimeEntriesCurrentUserConfigurationModalComponent } from './widgets/time-entries/current-user/time-entries-current-user-configuration.modal';

@NgModule({
  imports: [
    BrowserModule,
    FormsModule,
    DragDropModule,

    OpenprojectCommonModule,
    OpenprojectModalModule,
    OpenprojectWorkPackagesModule,
    OpenprojectWorkPackageGraphsModule,
    OpenprojectCalendarModule,
    OpenprojectTimeEntriesModule,

    OpenprojectAttachmentsModule,

    DynamicModule.withComponents([
      WidgetCustomTextComponent,
      WidgetDocumentsComponent,
      WidgetMembersComponent,
      WidgetNewsComponent,
      WidgetWpTableQuerySpaceComponent,
      WidgetWpGraphComponent,
      WidgetWpCalendarComponent,
      WidgetWpOverviewComponent,
      WidgetProjectDescriptionComponent,
      WidgetProjectDetailsComponent,
      WidgetProjectStatusComponent,
      WidgetSubprojectsComponent,
      WidgetTimeEntriesCurrentUserComponent,
      WidgetTimeEntriesProjectComponent]),

    // Support for inline editig fields
    OpenprojectFieldsModule,

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
    WidgetProjectDetailsComponent,
    WidgetProjectStatusComponent,
    WidgetSubprojectsComponent,
    WidgetTimeEntriesCurrentUserComponent,
    WidgetTimeEntriesProjectComponent,

    // Widget menus
    WidgetMenuComponent,
    WidgetWpTableMenuComponent,
    WidgetWpGraphMenuComponent,
    WidgetTimeEntriesCurrentUserMenuComponent,
    TimeEntriesCurrentUserConfigurationModalComponent,

    AddGridWidgetModal,

    WidgetHeaderComponent,
  ],
  exports: [
    GridComponent
  ]
})
export class OpenprojectGridsModule {
  constructor(injector:Injector) {
    registerWidgets(injector);
  }
}

export function registerWidgets(injector:Injector) {
  const hookService = injector.get(HookService);
  const i18n = injector.get(I18nService);

  hookService.register('gridWidgets', () => {

    const defaultColumns = ["id", "project", "type", "subject"];

    const assignedFilters = new ApiV3FilterBuilder();
    assignedFilters.add('assignee', '=', ["me"]);
    assignedFilters.add('status', 'o', []);

    const assignedProps = {
      "columns[]": defaultColumns,
      "filters": assignedFilters.toJson()
    };

    const accountableFilters = new ApiV3FilterBuilder();
    accountableFilters.add('responsible', '=', ["me"]);
    accountableFilters.add('status', 'o', []);

    const accountableProps = {
      "columns[]": defaultColumns,
      "filters": accountableFilters.toJson()
    };

    const createdFilters = new ApiV3FilterBuilder();
    createdFilters.add('author', '=', ["me"]);
    createdFilters.add('status', 'o', []);

    const createdProps = {
      "columns[]": defaultColumns,
      "filters": createdFilters.toJson()
    };

    const watchedFilters = new ApiV3FilterBuilder();
    watchedFilters.add('watcher', '=', ["me"]);
    watchedFilters.add('status', 'o', []);

    const watchedProps = {
      "columns[]": defaultColumns,
      "filters": watchedFilters.toJson()
    };

    return [
      {
        identifier: 'work_packages_assigned',
        component: WidgetWpTableQuerySpaceComponent,
        title: i18n.t(`js.grid.widgets.work_packages_assigned.title`),
        properties: {
          queryProps: assignedProps,
          name: i18n.t('js.grid.widgets.work_packages_assigned.title')
        }
      },
      {
        identifier: 'work_packages_accountable',
        component: WidgetWpTableQuerySpaceComponent,
        title: i18n.t(`js.grid.widgets.work_packages_accountable.title`),
        properties: {
          queryProps: accountableProps,
          name: i18n.t('js.grid.widgets.work_packages_accountable.title')
        }
      },
      {
        identifier: 'work_packages_created',
        component: WidgetWpTableQuerySpaceComponent,
        title: i18n.t(`js.grid.widgets.work_packages_created.title`),
        properties: {
          queryProps: createdProps,
          name: i18n.t('js.grid.widgets.work_packages_created.title')
        }
      },
      {
        identifier: 'work_packages_watched',
        component: WidgetWpTableQuerySpaceComponent,
        title: i18n.t(`js.grid.widgets.work_packages_watched.title`),
        properties: {
          queryProps: watchedProps,
          name: i18n.t('js.grid.widgets.work_packages_watched.title')
        }
      },
      {
        identifier: 'work_packages_table',
        component: WidgetWpTableQuerySpaceComponent,
        title: i18n.t(`js.grid.widgets.work_packages_table.title`),
        properties: {
          name: i18n.t('js.grid.widgets.work_packages_table.title')
        }
      },
      {
        identifier: 'work_packages_graph',
        component: WidgetWpGraphComponent,
        title: i18n.t(`js.grid.widgets.work_packages_graph.title`),
        properties: {
          name: i18n.t('js.grid.widgets.work_packages_graph.title')
        }
      },
      {
        identifier: 'work_packages_calendar',
        component: WidgetWpCalendarComponent,
        title: i18n.t(`js.grid.widgets.work_packages_calendar.title`),
        properties: {
          name: i18n.t('js.grid.widgets.work_packages_calendar.title')
        }
      },
      {
        identifier: 'work_packages_overview',
        component: WidgetWpOverviewComponent,
        title: i18n.t(`js.grid.widgets.work_packages_overview.title`),
        properties: {
          name: i18n.t('js.grid.widgets.work_packages_overview.title')
        }
      },
      {
        identifier: 'time_entries_current_user',
        component: WidgetTimeEntriesCurrentUserComponent,
        title: i18n.t(`js.grid.widgets.time_entries_current_user.title`),
        properties: {
          name: i18n.t('js.grid.widgets.time_entries_current_user.title'),
          days: [true, true, true, true, true, true, true]
        }
      },
      {
        identifier: 'time_entries_project',
        component: WidgetTimeEntriesProjectComponent,
        title: i18n.t(`js.grid.widgets.time_entries_list.title`),
        properties: {
          name: i18n.t('js.grid.widgets.time_entries_list.title'),
        }
      },
      {
        identifier: 'documents',
        component: WidgetDocumentsComponent,
        title: i18n.t(`js.grid.widgets.documents.title`),
        properties: {
          name: i18n.t('js.grid.widgets.documents.title')
        }
      },
      {
        identifier: 'members',
        component: WidgetMembersComponent,
        title: i18n.t(`js.grid.widgets.members.title`),
        properties: {
          name: i18n.t('js.grid.widgets.members.title')
        }
      },
      {
        identifier: 'news',
        component: WidgetNewsComponent,
        title: i18n.t(`js.grid.widgets.news.title`),
        properties: {
          name: i18n.t('js.grid.widgets.news.title')
        }
      },
      {
        identifier: 'project_description',
        component: WidgetProjectDescriptionComponent,
        title: i18n.t(`js.grid.widgets.project_description.title`),
        properties: {
          name: i18n.t('js.grid.widgets.project_description.title')
        }
      },
      {
        identifier: 'custom_text',
        component: WidgetCustomTextComponent,
        title: i18n.t(`js.grid.widgets.custom_text.title`),
        properties: {
          name: i18n.t('js.grid.widgets.custom_text.title'),
          text: {
            raw: ''
          }
        }
      },
      {
        identifier: 'project_details',
        component: WidgetProjectDetailsComponent,
        title: i18n.t(`js.grid.widgets.project_details.title`),
        properties: {
          name: i18n.t('js.grid.widgets.project_details.title')
        }
      },
      {
        identifier: 'project_status',
        component: WidgetProjectStatusComponent,
        title: i18n.t(`js.grid.widgets.project_status.title`),
        properties: {
          name: i18n.t('js.grid.widgets.project_status.title')
        }
      },
      {
        identifier: 'subprojects',
        component: WidgetSubprojectsComponent,
        title: i18n.t(`js.grid.widgets.subprojects.title`),
        properties: {
          name: i18n.t('js.grid.widgets.subprojects.title')
        }
      }
    ];
  });
}
