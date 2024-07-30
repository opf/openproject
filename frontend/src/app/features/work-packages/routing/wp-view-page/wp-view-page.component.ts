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

import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { take } from 'rxjs/operators';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { QueryParamListenerService } from 'core-app/features/work-packages/components/wp-query/query-param-listener.service';
import {
  PartitionedQuerySpacePageComponent,
  ToolbarButtonComponentDefinition,
} from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import { WorkPackageCreateButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-create-button/wp-create-button.component';
import { WorkPackageFilterButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-filter-button/wp-filter-button.component';
import { WorkPackageDetailsViewButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-details-view-button/wp-details-view-button.component';
import { WorkPackageTimelineButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-timeline-toggle-button/wp-timeline-toggle-button.component';
import { ZenModeButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import { WorkPackageSettingsButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-settings-button/wp-settings-button.component';
import { of } from 'rxjs';
import { WorkPackageFoldToggleButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-fold-toggle-button/wp-fold-toggle-button.component';
import { OpProjectIncludeComponent } from 'core-app/shared/components/project-include/project-include.component';
import { OpBaselineModalComponent } from 'core-app/features/work-packages/components/wp-baseline/baseline-modal/baseline-modal.component';

@Component({
  selector: 'wp-view-page',
  templateUrl: '../partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    // Absolute paths do not work for styleURLs :-(
    '../partitioned-query-space-page/partitioned-query-space-page.component.sass',
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    /** We need to provide the wpNotification service here to get correct save notifications for WP resources */
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService },
    QueryParamListenerService,
  ],
})
export class WorkPackageViewPageComponent extends PartitionedQuerySpacePageComponent implements OnInit {
  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: WorkPackageCreateButtonComponent,
      inputs: {
        stateName$: of(this.stateName),
        allowed: ['work_packages.createWorkPackage'],
      },
    },
    {
      component: OpProjectIncludeComponent,
    },
    {
      component: OpBaselineModalComponent,
      containerClasses: 'hidden-for-tablet',
    },
    {
      component: WorkPackageFilterButtonComponent,
    },
    {
      component: WorkPackageFoldToggleButtonComponent,
      show: () => !!(this.currentQuery && this.currentQuery.groupBy),
    },
    {
      component: WorkPackageDetailsViewButtonComponent,
      containerClasses: 'hidden-for-tablet',
    },
    {
      component: WorkPackageTimelineButtonComponent,
      containerClasses: 'hidden-for-tablet -no-spacing',
    },
    {
      component: ZenModeButtonComponent,
      containerClasses: 'hidden-for-tablet',
    },
    {
      component: WorkPackageSettingsButtonComponent,
    },
  ];

  ngOnInit() {
    super.ngOnInit();
    this.wpTableFilters.hidden.push(
      'project',
    );
    this.text.button_settings = this.I18n.t('js.button_settings');
  }

  protected additionalLoadingTime():Promise<unknown> {
    if (this.wpTableTimeline.isVisible) {
      return this.querySpace.timelineRendered.pipe(take(1)).toPromise();
    }
    return this.querySpace.tableRendered.valuesPromise() as Promise<unknown>;
  }

  protected shouldUpdateHtmlTitle():boolean {
    return this.$state.current.name === 'work-packages.partitioned.list';
  }

  private get stateName() {
    if (this.$state.current.name?.includes('gantt')) {
      return 'gantt.partitioned.list.new';
    }

    return 'work-packages.partitioned.list.new';
  }
}
