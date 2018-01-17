// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

import {opUiComponentsModule} from '../../angular-modules';
import {IAugmentedJQuery} from "angular";
import {WorkPackagesListChecksumService} from "core-components/wp-list/wp-list-checksum.service";

export const QUERY_MENU_ITEM_TYPE = 'query-menu-item';

export class WpQueryMenuItemController {
  private queryId:Number;
  private uiRouteStateName = 'work-packages.list';
  private uiRouteParams = { query_props: null, query_id: this.queryId };

  constructor(protected $element:IAugmentedJQuery,
              protected $scope:angular.IScope,
              protected $state:ng.ui.IStateService,
              protected $stateParams:ng.ui.IStateParamsService,
              protected $animate:any,
              protected wpListChecksumService:WorkPackagesListChecksumService) {
  }

  public $onInit() {
    this.$scope.$on('openproject.layout.activateMenuItem', () => this.setActiveState());

    this.$scope.$watchCollection(
      () => {
        return {
          query_id: this.$stateParams['query_id'],
        }
      }
      , () => this.setActiveState());

    this.$scope.$on('openproject.layout.removeMenuItem', (event, itemData) => {
      if (this.isEventForUs(itemData)) {
        this.removeItem();
      }
    });

    this.$scope.$on('openproject.layout.renameMenuItem', (event, itemData) => {
      if (this.isEventForUs(itemData)) {
        this.$element.find('.menu-item--title').html(itemData.objectName);
      }
    });

    this.$element.on('click', (event) => {
      if (event.shiftKey || event.ctrlKey || event.metaKey
        || event.which === 2) {
        return;
      }

      this.switchOrReload();
      event.preventDefault();
    });
  }

  private setActiveState() {
    const isCurrentState = this.$state.includes('work-packages') && this.isThisQueryId();
    this.$element.toggleClass('selected', isCurrentState );
  }

  private removeItem() {
    this.$animate.leave(this.$element.parent(), () => this.$scope.$destroy());
  }

  private isEventForUs(itemData:any) {
    return itemData.itemType === QUERY_MENU_ITEM_TYPE && itemData.objectId == this.queryId
  }

  private switchOrReload() {
    let opts = { reload: false };

    if (this.isThisQueryId()) {
      this.wpListChecksumService.clear();
      opts.reload = true;
    }

    this.$state.go(this.uiRouteStateName, this.uiRouteParams, opts);
  }

  private isThisQueryId() {
    return this.$stateParams['query_id'] && parseInt(this.$stateParams.query_id) === this.queryId
  }
}

opUiComponentsModule.directive('wpQueryMenuItem', () => {
  return {
    restrict: 'A',
    scope: {
      queryId: '=wpQueryMenuItem'
    },
    controller: WpQueryMenuItemController,
    controllerAs: '$ctrl',
    bindToController: true
  }
});
