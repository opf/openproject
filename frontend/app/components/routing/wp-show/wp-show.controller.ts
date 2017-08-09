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
import {HalResource} from "../../api/api-v3/hal-resources/hal-resource.service";
import {UserResource} from "../../api/api-v3/hal-resources/user-resource.service";
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageViewController} from "../wp-view-base/wp-view-base.controller";
import {WorkPackagesListChecksumService} from "../../wp-list/wp-list-checksum.service";
import {WorkPackageMoreMenuService} from '../../work-packages/work-package-more-menu.service'

export class WorkPackageShowController extends WorkPackageViewController {

  // Watcher properties
  public isWatched:boolean;
  public displayWatchButton:boolean;
  public watchers:any;

  // Properties
  public type:HalResource;
  public author:UserResource;
  public authorPath:string;
  public authorActive:boolean;
  public attachments:any;

  private wpMoreMenu:WorkPackageMoreMenuService;

  constructor(public $scope:ng.IScope,
              public $state:ng.ui.IStateService,
              protected wpMoreMenuService:WorkPackageMoreMenuService) {
    super($scope, $state.params['workPackageId']);
    this.observeWorkPackage();
  }

  protected init() {
    super.init();

    // initialization
    this.wpMoreMenu = new (this.wpMoreMenuService as any)(this.workPackage);

    this.wpMoreMenu.initialize().then(() => {
      this.$scope.permittedActions = this.wpMoreMenu.permittedActions;
      this.$scope.actionsAvailable = this.wpMoreMenu.actionsAvailable;
    });

    this.setWorkPackageScopeProperties(this.workPackage);
    this.text.goToList = this.I18n.t('js.button_back_to_list_view');

    this.$scope.triggerMoreMenuAction = this.wpMoreMenu.triggerMoreMenuAction.bind(this.wpMoreMenu);
  }

  public goToList() {
    this.$state.go('work-packages.list', this.$state.params);
  }

  private setWorkPackageScopeProperties(wp:WorkPackageResourceInterface) {
    this.isWatched = wp.hasOwnProperty('unwatch');
    this.displayWatchButton = wp.hasOwnProperty('unwatch') || wp.hasOwnProperty('watch');

    // watchers
    if (wp.watchers) {
      this.watchers = (wp.watchers as any).elements;
    }

    // Type
    this.type = wp.type;

    // Author
    this.author = wp.author;
    this.authorPath = this.author.showUserPath as string;
    this.authorActive = this.author.isActive;

    // Attachments
    this.attachments = wp.attachments.elements;
  }
}

wpControllersModule.controller('WorkPackageShowController', WorkPackageShowController);
