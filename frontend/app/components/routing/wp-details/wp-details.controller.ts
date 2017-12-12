// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {wpControllersModule} from "../../../angular-modules";
import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {States} from "../../states.service";
import {WorkPackageTableSelection} from "../../wp-fast-table/state/wp-table-selection.service";
import {KeepTabService} from "../../wp-panels/keep-tab/keep-tab.service";
import {WorkPackageViewController} from "../wp-view-base/wp-view-base.controller";
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';
import {FirstRouteService} from "core-components/routing/first-route-service";
import {WorkPackageTableFocusService} from "core-components/wp-fast-table/state/wp-table-focus.service";

export class WorkPackageDetailsController extends WorkPackageViewController {

  constructor(public $scope:ng.IScope,
              public states:States,
              public firstRoute:FirstRouteService,
              public keepTab:KeepTabService,
              public wpTableSelection:WorkPackageTableSelection,
              public wpTableFocus:WorkPackageTableFocusService,
              public $state:ng.ui.IStateService) {
    super($scope, $state.params['workPackageId']);
    this.observeWorkPackage();

    let wpId = $state.params['workPackageId'];
    let focusedWP = this.wpTableFocus.focusedWorkPackage;

    if (!focusedWP) {
      // Focus on the work package if we're the first route
      const isFirstRoute = firstRoute.name === 'work-packages.list.details.overview';
      const isSameID = firstRoute.params && wpId === firstRoute.params.workPackageI;
      this.wpTableFocus.updateFocus(wpId, (isFirstRoute && isSameID));
    }

    if (this.wpTableSelection.isEmpty) {
      this.wpTableSelection.setRowState(wpId, true);
    }

    scopedObservable(
      $scope,
      this.wpTableFocus.whenChanged()
    ).subscribe(newId => {
        if (wpId !== newId && $state.includes('work-packages.list.details')) {
          $state.go(
            ($state.current.name as string),
            {workPackageId: newId, focus: false }
          );
        }
      });
  }

  public close() {
    this.$state.go('work-packages.list', this.$state.params);
  }

  public switchToFullscreen() {
    this.$state.go(this.keepTab.currentShowState, this.$state.params);
  }

  public get shouldFocus() {
    return this.$state.params.focus === true;
  }

  protected initializeTexts() {
    super.initializeTexts();
    this.text.closeDetailsView = this.I18n.t('js.button_close_details');
    this.text.goTofullScreen = this.I18n.t('js.work_packages.message_successful_show_in_fullscreen');
  }
}

wpControllersModule.controller('WorkPackageDetailsController', WorkPackageDetailsController);
