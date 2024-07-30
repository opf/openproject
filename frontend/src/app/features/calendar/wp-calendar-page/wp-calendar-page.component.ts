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

import {
  ChangeDetectionStrategy,
  Component,
  ViewChild,
} from '@angular/core';
import { WorkPackagesCalendarComponent } from 'core-app/features/calendar/wp-calendar/wp-calendar.component';
import {
  DynamicComponentDefinition,
  PartitionedQuerySpacePageComponent,
  ToolbarButtonComponentDefinition,
  ViewPartitionState,
} from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import { WorkPackageFilterContainerComponent } from 'core-app/features/work-packages/components/filters/filter-container/filter-container.directive';
import { WorkPackageFilterButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-filter-button/wp-filter-button.component';
import { ZenModeButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import { WorkPackageSettingsButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-settings-button/wp-settings-button.component';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { QueryParamListenerService } from 'core-app/features/work-packages/components/wp-query/query-param-listener.service';
import { OpProjectIncludeComponent } from 'core-app/shared/components/project-include/project-include.component';
import { calendarRefreshRequest } from 'core-app/features/calendar/calendar.actions';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

@Component({
  templateUrl: '../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    QueryParamListenerService,
  ],
})
export class WorkPackagesCalendarPageComponent extends PartitionedQuerySpacePageComponent {
  @InjectField(ActionsService) actions$:ActionsService;

  @ViewChild(WorkPackagesCalendarComponent, { static: true }) calendarElement:WorkPackagesCalendarComponent;

  text = {
    title: this.I18n.t('js.calendar.title'),
    unsaved_title: this.I18n.t('js.calendar.unsaved_title'),
  };

  /** Go back using back-button */
  backButtonCallback:() => void;

  /** Current query title to render */
  selectedTitle = this.text.unsaved_title;

  filterContainerDefinition:DynamicComponentDefinition = {
    component: WorkPackageFilterContainerComponent,
  };

  /** We need to pass the correct partition state to the view to manage the grid */
  currentPartition:ViewPartitionState = '-split';

  /** Show a toolbar */
  showToolbar = true;

  /** Toolbar is not editable */
  titleEditingEnabled = false;

  /** Saveable */
  showToolbarSaveButton = true;

  /** Toolbar is always enabled */
  toolbarDisabled = false;

  /** Define the buttons shown in the toolbar */
  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: OpProjectIncludeComponent,
    },
    {
      component: WorkPackageFilterButtonComponent,
    },
    {
      component: ZenModeButtonComponent,
    },
    {
      component: WorkPackageSettingsButtonComponent,
      containerClasses: 'hidden-for-tablet',
      inputs: {
        hideTableOptions: true,
        showCalendarSharingOption: true,
      },
    },
  ];

  /**
   * We need to set the current partition to the grid to ensure
   * either side gets expanded to full width if we're not in '-split' mode.
   *
   * @param state The current or entering state
   */
  setPartition(state:{ data:{ partition?:ViewPartitionState } }):void {
    this.currentPartition = state.data?.partition || '-split';
  }

  protected staticQueryName(_query:QueryResource):string {
    return this.text.unsaved_title;
  }

  /**
   * @protected
   */
  protected loadInitialQuery():void {
    // We never load the initial query as the calendar service does all that.
  }

  /**
   * Instead of refreshing the query space diretly, send an effect so fullcalendar can reload individually
   */
  refresh(visibly = false, _firstPage = false):void {
    this.actions$.dispatch(calendarRefreshRequest({ showLoading: visibly }));
  }
}
