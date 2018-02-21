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

import {UserResource} from '../../api/api-v3/hal-resources/user-resource.service';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageViewController} from '../wp-view-base/wp-view-base.controller';
import {WorkPackageMoreMenuService} from '../../work-packages/work-package-more-menu.service';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {StateService} from '@uirouter/core';
import {TypeResource} from 'core-components/api/api-v3/hal-resources/type-resource.service';
import {Component, Inject, Injector} from '@angular/core';
import {$stateToken, wpMoreMenuServiceToken} from 'core-app/angular4-transition-utils';
import {WorkPackageTableSelection} from 'core-components/wp-fast-table/state/wp-table-selection.service';
import {States} from 'core-components/states.service';
import {FirstRouteService} from 'core-components/routing/first-route-service';
import {KeepTabService} from 'core-components/wp-single-view-tabs/keep-tab/keep-tab.service';

@Component({
  template: require('!!raw-loader!./wp-full-view.html'),
  selector: 'wp-full-view-entry',
  // Required class to support inner scrolling on page
  host: { 'class': 'work-packages-page--ui-view' }
})
export class WorkPackagesFullViewComponent extends WorkPackageViewController {

  // Watcher properties
  public isWatched:boolean;
  public displayWatchButton:boolean;
  public watchers:any;

  // Properties
  public type:TypeResource;
  public author:UserResource;
  public authorPath:string;
  public authorActive:boolean;
  public attachments:any;

  // More menu
  public permittedActions:any;
  public actionsAvailable:any;
  public triggerMoreMenuAction:Function;

  private wpMoreMenu:WorkPackageMoreMenuService;

  constructor(public injector:Injector,
              public states:States,
              public firstRoute:FirstRouteService,
              public keepTab:KeepTabService,
              public wpTableSelection:WorkPackageTableSelection,
              public wpTableFocus:WorkPackageTableFocusService,
              @Inject(wpMoreMenuServiceToken) private wpMoreMenuServiceFactory:any,
              @Inject($stateToken) readonly $state:StateService) {
    super(injector, $state.params['workPackageId']);
    this.observeWorkPackage();
  }

  protected initializeTexts() {
    super.initializeTexts();

    this.text.full_view = {
      button_more: this.I18n.t('js.button_more')
    };
  }

  protected init() {
    super.init();

    // Set Focused WP
    this.wpTableFocus.updateFocus(this.workPackage.id);

    // initialization
    this.wpMoreMenu = new this.wpMoreMenuServiceFactory(this.workPackage) as WorkPackageMoreMenuService;

    this.wpMoreMenu.initialize().then(() => {
      this.permittedActions = this.wpMoreMenu.permittedActions;
      this.actionsAvailable = this.wpMoreMenu.actionsAvailable;
    });

    this.setWorkPackageScopeProperties(this.workPackage);
    this.text.goToList = this.I18n.t('js.button_back_to_list_view');

    this.triggerMoreMenuAction = this.wpMoreMenu.triggerMoreMenuAction.bind(this.wpMoreMenu);
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
