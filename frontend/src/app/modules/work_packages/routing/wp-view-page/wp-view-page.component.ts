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

import { ChangeDetectionStrategy, Component, OnInit } from "@angular/core";
import { take } from "rxjs/operators";
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { QueryParamListenerService } from "core-components/wp-query/query-param-listener.service";
import {
  PartitionedQuerySpacePageComponent,
  ToolbarButtonComponentDefinition,
} from "core-app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component";
import { WorkPackageCreateButtonComponent } from "core-components/wp-buttons/wp-create-button/wp-create-button.component";
import { WorkPackageFilterButtonComponent } from "core-components/wp-buttons/wp-filter-button/wp-filter-button.component";
import { WorkPackageViewToggleButton } from "core-components/wp-buttons/wp-view-toggle-button/work-package-view-toggle-button.component";
import { WorkPackageDetailsViewButtonComponent } from "core-components/wp-buttons/wp-details-view-button/wp-details-view-button.component";
import { WorkPackageTimelineButtonComponent } from "core-components/wp-buttons/wp-timeline-toggle-button/wp-timeline-toggle-button.component";
import { ZenModeButtonComponent } from "core-components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component";
import { WorkPackageSettingsButtonComponent } from "core-components/wp-buttons/wp-settings-button/wp-settings-button.component";
import { of } from "rxjs";
import { WorkPackageFoldToggleButtonComponent } from "core-components/wp-buttons/wp-fold-toggle-button/wp-fold-toggle-button.component";

@Component({
  selector: 'wp-view-page',
  templateUrl: '../../../work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
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
        stateName$: of("work-packages.partitioned.list.new"),
        allowed: ['work_packages.createWorkPackage'],
      },
    },
    {
      component: WorkPackageFilterButtonComponent,
    },
    {
      component: WorkPackageViewToggleButton,
      containerClasses: 'hidden-for-mobile',
    },
    {
      component: WorkPackageFoldToggleButtonComponent,
      show: () => {
        return !!(this.currentQuery && this.currentQuery.groupBy);
      },
    },
    {
      component: WorkPackageDetailsViewButtonComponent,
      containerClasses: 'hidden-for-mobile',
    },
    {
      component: WorkPackageTimelineButtonComponent,
      containerClasses: 'hidden-for-mobile -no-spacing',
    },
    {
      component: ZenModeButtonComponent,
      containerClasses: 'hidden-for-mobile',
    },
    {
      component: WorkPackageSettingsButtonComponent,
    },
  ];

  ngOnInit() {
    super.ngOnInit();
    this.text.button_settings = this.I18n.t('js.button_settings');
  }

  protected additionalLoadingTime():Promise<unknown> {
    if (this.wpTableTimeline.isVisible) {
      return this.querySpace.timelineRendered.pipe(take(1)).toPromise();
    } else {
      return this.querySpace.tableRendered.valuesPromise() as Promise<unknown>;
    }
  }

  protected shouldUpdateHtmlTitle():boolean {
    return this.$state.current.name === 'work-packages.partitioned.list';
  }
}
