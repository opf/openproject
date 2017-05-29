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
import {WorkPackageButtonController, wpButtonDirective} from '../wp-buttons.module';
import {KeepTabService} from '../../wp-panels/keep-tab/keep-tab.service';
import {States} from '../../states.service';


export class WorkPackageDetailsViewButtonController extends WorkPackageButtonController {
  public projectIdentifier:string;
  public accessKey:number = 8;
  public activeState:string = 'work-packages.list.details';
  public listState: string = 'work-packages.list';
  public buttonId:string = 'work-packages-details-view-button';
  public buttonClass:string = 'toolbar-icon';
  public iconClass:string = 'icon-info2';

  public activateLabel:string;
  public deactivateLabel:string;

  constructor(
    public $state:ng.ui.IStateService,
    public states:States,
    public I18n:op.I18n,
    public loadingIndicator:any,
    public keepTab:KeepTabService) {
    'ngInject';
    super(I18n);

    this.activateLabel = I18n.t('js.button_open_details');
    this.deactivateLabel = I18n.t('js.button_close_details');
  }

  public get label():string {
    if (this.isActive()) {
      return this.deactivateLabel;
    } else {
      return this.activateLabel;
    }
  }

  public isToggle():boolean {
    return true;
  }

  public isActive():boolean {
    return this.$state.includes(this.activeState);
  }

  public performAction() {
    if (this.isActive()) {
      this.openListView();
    } else {
      this.openDetailsView();
    }
  }

  public openListView() {
    var params = {
      projectPath: this.projectIdentifier
    };

    angular.extend(params, this.$state.params);
    this.$state.go(this.listState, params);
  }

  public openDetailsView() {
    var params = {
      workPackageId: this.states.focusedWorkPackage.value,
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
