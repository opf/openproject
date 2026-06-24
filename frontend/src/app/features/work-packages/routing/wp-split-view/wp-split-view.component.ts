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

import { ChangeDetectionStrategy, Component, HostListener, Input, OnInit, Type, inject } from '@angular/core';
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
import { RecentItemsService } from 'core-app/core/recent-items.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import {
  WorkPackageTabsService,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { TabComponent } from 'core-app/features/work-packages/components/wp-tabs/components/wp-tab-wrapper/tab';
import { resolveRoutingId } from 'core-app/features/work-packages/helpers/work-package-id-resolvers';

@Component({
  templateUrl: './wp-split-view.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'op-wp-split-view',
  providers: [
    WpSingleViewService,
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService },
  ],
  standalone: false,
})
export class WorkPackageSplitViewComponent extends WorkPackageSingleViewBase implements OnInit {
  states = inject(States);
  firstRoute = inject(FirstRouteService);
  keepTab = inject(KeepTabService);
  wpTableSelection = inject(WorkPackageViewSelectionService);
  wpTableFocus = inject(WorkPackageViewFocusService);
  recentItemsService = inject(RecentItemsService);
  readonly $state = inject(StateService);
  readonly urlParams = inject(UrlParamsService);
  readonly backRouting = inject(BackRoutingService);
  readonly wpTabs = inject(WorkPackageTabsService);

  hasState = !!this.$state.current;
  /** Reference to the base route e.g., work-packages.partitioned.list or bim.partitioned.split */
  private baseRoute = (this.$state.current?.data as { baseRoute?:string } | undefined)?.baseRoute ?? '';

  @Input() showTabs = true;

  @Input() resizerClass = 'work-packages-partitioned-page--content-right';

    // enable other parts of the application to trigger an immediate update
  // e.g. a stimulus controller
  // currently used by the new activities tab which does its own polling
  @HostListener('document:ian-update-immediate')
  triggerImmediateUpdate() {
    this.storeService.reload();
  }

  ngOnInit():void {
    this.observeWorkPackage();

    this.wpTableFocus.whenNavigationRequested()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((newId) => {
        const currentId = this.workPackage?.id ?? this.workPackageId;
        const idSame = currentId.toString() === newId.toString();
        if (!idSame && this.$state.includes(`${this.baseRoute}.details`)) {
          void this.$state.go(
            (this.$state.current.name!),
            { workPackageId: resolveRoutingId(this.states, newId.toString()), focus: false },
          );
        }
      });
  }

  /**
   * Set focus, selection, and recent-items after the WP has loaded.
   *
   * Intentionally deferred from ngOnInit because the route param
   * (this.workPackageId) may be a semantic identifier like "PROJ-7",
   * but focus/selection services are keyed by numeric PK. By the time
   * init() runs, this.workPackage.id is guaranteed to be the numeric PK.
   */
  protected override init():void {
    super.init();
    const numericId = this.workPackage.id!;
    this.wpTableFocus.updateFocus(numericId, false);

    if (this.wpTableSelection.isEmpty) {
      this.wpTableSelection.setRowState(numericId, true);
    }

    this.recentItemsService.add(numericId);
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
