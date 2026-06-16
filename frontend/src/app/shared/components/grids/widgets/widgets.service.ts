import { inject, Injectable } from '@angular/core';
import { WidgetRegistration } from 'core-app/shared/components/grids/grid/grid.component';
import { HookService } from 'core-app/features/plugins/hook-service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import {
  WidgetWpTableQuerySpaceComponent,
} from 'core-app/shared/components/grids/widgets/wp-table/wp-table-qs.component';
import { WidgetWpGraphComponent } from 'core-app/shared/components/grids/widgets/wp-graph/wp-graph.component';
import { WidgetWpCalendarComponent } from 'core-app/shared/components/grids/widgets/wp-calendar/wp-calendar.component';
import { WidgetWpOverviewComponent } from 'core-app/shared/components/grids/widgets/wp-overview/wp-overview.component';
import {
  WidgetTimeEntriesCurrentUserComponent,
} from 'core-app/shared/components/grids/widgets/time-entries/current-user/time-entries-current-user.component';
import {
  WidgetTimeEntriesProjectComponent,
} from 'core-app/shared/components/grids/widgets/time-entries/project/time-entries-project.component';
import { WidgetDocumentsComponent } from 'core-app/shared/components/grids/widgets/documents/documents.component';
import { WidgetMembersComponent } from 'core-app/shared/components/grids/widgets/members/members.component';
import { WidgetNewsComponent } from 'core-app/shared/components/grids/widgets/news/news.component';
import {
  WidgetProjectDescriptionComponent,
} from 'core-app/shared/components/grids/widgets/project-description/project-description.component';
import { WidgetCustomTextComponent } from 'core-app/shared/components/grids/widgets/custom-text/custom-text.component';
import {
  WidgetProjectStatusComponent,
} from 'core-app/shared/components/grids/widgets/project-status/project-status.component';
import { WidgetSubprojectsComponent } from 'core-app/shared/components/grids/widgets/subprojects/subprojects.component';
import {
  WidgetFavoriteProjectsComponent,
} from 'core-app/shared/components/grids/widgets/favorite-projects/widget-favorite-projects.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Injectable()
export class GridWidgetsService {
  private Hook = inject(HookService);
  private I18n = inject(I18nService);

  private registeredWidgets = this.buildWidgets();

  public get registered() {
    return this.registeredWidgets;
  }

  private buildWidgets() {
    let registeredWidgets:WidgetRegistration[] = this.buildDefaultWidgets();

    _.each(this.Hook.call('gridWidgets'), (registration:WidgetRegistration[]) => {
      registeredWidgets = registeredWidgets.concat(registration);
    });

    return registeredWidgets;
  }

  private buildDefaultWidgets():WidgetRegistration[] {
    const defaultColumns = ['id', 'project', 'type', 'subject'];

    const assignedFilters = new ApiV3FilterBuilder();
    assignedFilters.add('assignee', '=', ['me']);
    assignedFilters.add('status', 'o', []);

    const assignedProps = {
      'columns[]': defaultColumns,
      filters: assignedFilters.toJson(),
    };

    const accountableFilters = new ApiV3FilterBuilder();
    accountableFilters.add('responsible', '=', ['me']);
    accountableFilters.add('status', 'o', []);

    const accountableProps = {
      'columns[]': defaultColumns,
      filters: accountableFilters.toJson(),
    };

    const createdFilters = new ApiV3FilterBuilder();
    createdFilters.add('author', '=', ['me']);
    createdFilters.add('status', 'o', []);

    const createdProps = {
      'columns[]': defaultColumns,
      filters: createdFilters.toJson(),
    };

    const watchedFilters = new ApiV3FilterBuilder();
    watchedFilters.add('watcher', '=', ['me']);
    watchedFilters.add('status', 'o', []);

    const watchedProps = {
      'columns[]': defaultColumns,
      filters: watchedFilters.toJson(),
    };

    return [
      {
        identifier: 'work_packages_assigned',
        component: WidgetWpTableQuerySpaceComponent,
        title: this.I18n.t('js.grid.widgets.work_packages_assigned.title'),
        properties: {
          queryProps: assignedProps,
          name: this.I18n.t('js.grid.widgets.work_packages_assigned.title'),
        },
      },
      {
        identifier: 'work_packages_accountable',
        component: WidgetWpTableQuerySpaceComponent,
        title: this.I18n.t('js.grid.widgets.work_packages_accountable.title'),
        properties: {
          queryProps: accountableProps,
          name: this.I18n.t('js.grid.widgets.work_packages_accountable.title'),
        },
      },
      {
        identifier: 'work_packages_created',
        component: WidgetWpTableQuerySpaceComponent,
        title: this.I18n.t('js.grid.widgets.work_packages_created.title'),
        properties: {
          queryProps: createdProps,
          name: this.I18n.t('js.grid.widgets.work_packages_created.title'),
        },
      },
      {
        identifier: 'work_packages_watched',
        component: WidgetWpTableQuerySpaceComponent,
        title: this.I18n.t('js.grid.widgets.work_packages_watched.title'),
        properties: {
          queryProps: watchedProps,
          name: this.I18n.t('js.grid.widgets.work_packages_watched.title'),
        },
      },
      {
        identifier: 'work_packages_table',
        component: WidgetWpTableQuerySpaceComponent,
        title: this.I18n.t('js.grid.widgets.work_packages_table.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.work_packages_table.title'),
        },
      },
      {
        identifier: 'work_packages_graph',
        component: WidgetWpGraphComponent,
        title: this.I18n.t('js.grid.widgets.work_packages_graph.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.work_packages_graph.title'),
        },
      },
      {
        identifier: 'work_packages_calendar',
        component: WidgetWpCalendarComponent,
        title: this.I18n.t('js.grid.widgets.work_packages_calendar.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.work_packages_calendar.title'),
        },
      },
      {
        identifier: 'work_packages_overview',
        component: WidgetWpOverviewComponent,
        title: this.I18n.t('js.grid.widgets.work_packages_overview.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.work_packages_overview.title'),
        },
      },
      {
        identifier: 'time_entries_current_user',
        component: WidgetTimeEntriesCurrentUserComponent,
        title: this.I18n.t('js.grid.widgets.time_entries_current_user.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.time_entries_current_user.title'),
          days: [true, true, true, true, true, true, true],
        },
      },
      {
        identifier: 'time_entries_list',
        component: WidgetTimeEntriesProjectComponent,
        title: this.I18n.t('js.grid.widgets.time_entries_list.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.time_entries_list.title'),
        },
      },
      {
        identifier: 'documents',
        component: WidgetDocumentsComponent,
        title: this.I18n.t('js.grid.widgets.documents.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.documents.title'),
        },
      },
      {
        identifier: 'members',
        component: WidgetMembersComponent,
        title: this.I18n.t('js.grid.widgets.members.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.members.title'),
        },
      },
      {
        identifier: 'news',
        component: WidgetNewsComponent,
        title: this.I18n.t('js.grid.widgets.news.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.news.title'),
        },
      },
      {
        identifier: 'project_description',
        component: WidgetProjectDescriptionComponent,
        title: this.I18n.t('js.grid.widgets.project_description.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.project_description.title'),
        },
      },
      {
        identifier: 'custom_text',
        component: WidgetCustomTextComponent,
        title: this.I18n.t('js.grid.widgets.custom_text.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.custom_text.title'),
          text: {
            raw: '',
          },
        },
      },
      {
        identifier: 'project_status',
        component: WidgetProjectStatusComponent,
        title: this.I18n.t('js.grid.widgets.project_status.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.project_status.title'),
        },
      },
      {
        identifier: 'subprojects',
        component: WidgetSubprojectsComponent,
        title: this.I18n.t('js.grid.widgets.subprojects.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.subprojects.title'),
        },
      },
      {
        identifier: 'project_favorites',
        component: WidgetFavoriteProjectsComponent,
        title: this.I18n.t('js.grid.widgets.project_favorites.title'),
        properties: {
          name: this.I18n.t('js.grid.widgets.project_favorites.title'),
        },
      },
    ];
  }
}
