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

import { ChangeDetectionStrategy, Component, Injector, OnInit } from '@angular/core';
import { StateService } from '@uirouter/core';
import { WorkPackageViewFocusService } from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { States } from "core-components/states.service";
import { FirstRouteService } from "core-app/modules/router/first-route-service";
import { KeepTabService } from "core-components/wp-single-view-tabs/keep-tab/keep-tab.service";
import { WorkPackageViewSelectionService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import { WorkPackageSingleViewBase } from "core-app/modules/work_packages/routing/wp-view-base/work-package-single-view.base";
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { BackRoutingService } from "core-app/modules/common/back-routing/back-routing.service";

@Component({
  templateUrl: './wp-split-view.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-split-view-entry',
  providers: [
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService }
  ]
})
export class WorkPackageSplitViewComponent extends WorkPackageSingleViewBase implements OnInit {

  /** Reference to the base route e.g., work-packages.partitioned.list or bim.partitioned.split */
  private baseRoute:string = this.$state.current.data.baseRoute;

  constructor(public injector:Injector,
              public states:States,
              public firstRoute:FirstRouteService,
              public keepTab:KeepTabService,
              public wpTableSelection:WorkPackageViewSelectionService,
              public wpTableFocus:WorkPackageViewFocusService,
              readonly $state:StateService,
              readonly backRouting:BackRoutingService) {
    super(injector, $state.params['workPackageId']);
  }

  ngOnInit():void {
    this.observeWorkPackage();

    const wpId = this.$state.params['workPackageId'];
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
        this.untilDestroyed()
      )
      .subscribe(newId => {
        const idSame = wpId.toString() === newId.toString();
        if (!idSame && this.$state.includes(`${this.baseRoute}.details`)) {
          this.$state.go(
            (this.$state.current.name as string),
            { workPackageId: newId, focus: false }
          );
        }
      });
  }


  public close() {
    this.$state.go(this.baseRoute, this.$state.params);
  }

  public switchToFullscreen() {
    this.$state.go(this.keepTab.currentShowState, this.$state.params);
  }

  public get shouldFocus() {
    return this.$state.params.focus === true;
  }

  public showBackButton():boolean {
    return this.baseRoute.includes('bim');
  }

  public backToList() {
    this.backRouting.goToBaseState();
  }

  protected initializeTexts() {
    super.initializeTexts();
    this.text.closeDetailsView = this.I18n.t('js.button_close_details');
    this.text.goTofullScreen = this.I18n.t('js.work_packages.message_successful_show_in_fullscreen');
  }
}
