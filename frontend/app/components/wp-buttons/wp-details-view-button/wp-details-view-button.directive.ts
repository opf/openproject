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

import {wpButtonsModule} from '../../../angular-modules';
import {WorkPackageNavigationButtonController, wpButtonDirective} from '../wp-buttons.module';
import {KeepTabService} from '../../wp-panels/keep-tab/keep-tab.service';

export class WorkPackageDetailsViewButtonController extends WorkPackageNavigationButtonController {
  public projectIdentifier:number;

  public accessKey:number = 8;
  public activeState:string = 'work-packages.list.details';
  public buttonId:string = 'work-packages-details-view-button';
  public iconClass:string = 'icon-view-split';

  constructor(public $state,
              public states,
              public I18n,
              public loadingIndicator,
              public keepTab:KeepTabService) {
    'ngInject';

    super($state, I18n);
  }

  public get labelKey():string {
    return 'js.button_details_view';
  }

  public performAction() {
    this.openDetailsView();
  }

  public openDetailsView() {
    var params = {
      workPackageId: this.states.focusedWorkPackage.getCurrentValue(),
      projectPath: this.projectIdentifier,
    };

    angular.extend(params, this.$state.params);

    this.loadingIndicator.mainPage = this.$state.go.apply(
      this.$state, [this.keepTab.currentDetailsState, params]);
  }
}

function wpDetailsViewButton() {
  return wpButtonDirective({
    scope: {
      projectIdentifier: '=?'
    },

    controller: WorkPackageDetailsViewButtonController,
  });
}

wpButtonsModule.directive('wpDetailsViewButton', wpDetailsViewButton);
