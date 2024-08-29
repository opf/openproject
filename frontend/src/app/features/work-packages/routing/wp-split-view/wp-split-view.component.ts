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

import { ChangeDetectionStrategy, Component, Injector, Input, OnInit, Type } from '@angular/core';
import { StateService } from '@uirouter/core';
import {
  WorkPackageViewFocusService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { States } from 'core-app/core/states/states.service';
import { FirstRouteService } from 'core-app/core/routing/first-route-service';
import {
  KeepTabService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import {
  WorkPackageViewSelectionService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import {
  WorkPackageSingleViewBase,
} from 'core-app/features/work-packages/routing/wp-view-base/work-package-single-view.base';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { BackRoutingService } from 'core-app/features/work-packages/components/back-routing/back-routing.service';
import { WpSingleViewService } from 'core-app/features/work-packages/routing/wp-view-base/state/wp-single-view.service';
import { CommentService } from 'core-app/features/work-packages/components/wp-activity/comment-service';
import { RecentItemsService } from 'core-app/core/recent-items.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import {
  WorkPackageTabsService,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { TabComponent } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/tab';

@Component({
  templateUrl: './wp-split-view.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'op-wp-split-view',
  providers: [
    WpSingleViewService,
    CommentService,
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService },
  ],
})
export class WorkPackageSplitViewComponent extends WorkPackageSingleViewBase implements OnInit {
  hasState:boolean = !!this.$state.current;
  /** Reference to the base route e.g., work-packages.partitioned.list or bim.partitioned.split */
  private baseRoute:string = this.$state.current?.data?.baseRoute as string;

  @Input() workPackageId:string;
  @Input() showTabs = true;
  @Input() activeTab?:string;

  @Input() resizerClass = 'work-packages-partitioned-page--content-right';

  constructor(
    public injector:Injector,
    public states:States,
    public firstRoute:FirstRouteService,
    public keepTab:KeepTabService,
    public wpTableSelection:WorkPackageViewSelectionService,
    public wpTableFocus:WorkPackageViewFocusService,
    public recentItemsService:RecentItemsService,
    readonly $state:StateService,
    readonly urlParams:UrlParamsService,
    readonly backRouting:BackRoutingService,
    readonly wpTabs:WorkPackageTabsService,
  ) {
    super(injector, $state.params.workPackageId);
  }

  ngOnInit():void {
    this.observeWorkPackage();

    const wpId = (this.$state.params.workPackageId || this.workPackageId) as string;
    const focusedWP = this.wpTableFocus.focusedWorkPackage;

    if (!focusedWP) {
      // Focus on the work package if we're the first route
      const isFirstRoute = this.firstRoute.name === `${this.baseRoute}.details.overview`;
      const isSameID = this.firstRoute.params && wpId === this.firstRoute.params.workPackageI;
      this.wpTableFocus.updateFocus(wpId, (isFirstRoute && isSameID));
    } else {
      this.wpTableFocus.updateFocus(wpId, false);
    }

    if (this.wpTableSelection.isEmpty) {
      this.wpTableSelection.setRowState(wpId, true);
    }

    this.wpTableFocus.whenChanged()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((newId) => {
        const idSame = wpId.toString() === newId.toString();
        if (!idSame && this.$state.includes(`${this.baseRoute}.details`)) {
          this.$state.go(
            (this.$state.current.name as string),
            { workPackageId: newId, focus: false },
          );
        }
      });
    this.recentItemsService.add(wpId);
  }

  get shouldFocus():boolean {
    return this.$state.params.focus === true;
  }

  get activeTabComponent():Type<TabComponent>|undefined {
    return this
      .wpTabs
      .tabs
      .find((tab) => tab.id === this.activeTab)
      ?.component;
  }

  showBackButton():boolean {
    return this.baseRoute?.includes('bim');
  }

  backToList():void {
    this.backRouting.goToBaseState();
  }

  protected handleLoadingError(error:unknown):void {
    const message = this.notificationService.retrieveErrorMessage(error);

    // Go back to the base route, closing this split view
    void this.$state.go(
      this.baseRoute,
      { flash_message: { type: 'error', message } },
    );
  }
}
