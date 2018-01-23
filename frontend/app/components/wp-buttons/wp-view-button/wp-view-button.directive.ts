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
import {States} from '../../states.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {StateService} from '@uirouter/angularjs';

export class WorkPackageViewButtonController extends WorkPackageNavigationButtonController {
  public workPackageId:number;

  public accessKey:number = 9;
  public activeState:string = 'work-packages.show';
  public buttonId:string = 'work-packages-show-view-button';
  public iconClass:string = 'icon-view-fullscreen';

  constructor(
    public $state:StateService,
    public states:States,
    public I18n:op.I18n,
    public wpTableFocus:WorkPackageTableFocusService,
    public keepTab:KeepTabService) {
    'ngInject';

    super($state, I18n);
  }

  public get labelKey():string {
    return 'js.button_show_view';
  }

  public performAction() {
    this.openWorkPackageShowView();
  }

  public openWorkPackageShowView() {
    let args:any = ['work-packages.new', this.$state.params];
    let id = this.$state.params['workPackageId'] || this.workPackageId || this.wpTableFocus.focusedWorkPackage;

    if (!this.$state.is('work-packages.list.new')) {
      let params = {
        workPackageId: id
      };
      args = [this.keepTab.currentShowState, params];

      angular.extend(params, this.$state.params);
    }

    this.$state.go.apply(this.$state, args);
  }
}

function wpViewButton():ng.IDirective {
  return wpButtonDirective({
    scope: {
      workPackageId: '=?',
    },

    controller: WorkPackageViewButtonController,
  });
}

wpButtonsModule.directive('wpViewButton', wpViewButton);
