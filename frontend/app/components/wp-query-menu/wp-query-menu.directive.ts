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
import {IAugmentedJQuery} from 'angular';
import {WorkPackagesListChecksumService} from 'core-components/wp-list/wp-list-checksum.service';
import {LinkHandling} from 'core-components/common/link-handling/link-handling';
import {
  QueryMenuEvent,
  QueryMenuService
} from 'core-components/wp-query-menu/wp-query-menu.service';

export const QUERY_MENU_ITEM_TYPE = 'query-menu-item';

export class WpQueryMenuController {
  private currentQueryId?:string;
  private uiRouteStateName = 'work-packages.list';
  private container:ng.IAugmentedJQuery;

  constructor(protected $element:IAugmentedJQuery,
              protected $state:ng.ui.IStateService,
              protected $scope:ng.IScope,
              protected $stateParams:ng.ui.IStateParamsService,
              protected queryMenu:QueryMenuService,
              protected $animate:any,
              protected wpListChecksumService:WorkPackagesListChecksumService) {
  }

  public $onInit() {
    this.container = this.$element.parent().find('ul.menu-children');

    this.queryMenu
      .on('remove')
      .subscribe((e:QueryMenuEvent) => this.removeItem(e));

    this.queryMenu
      .on('add')
      .subscribe((e:QueryMenuEvent) => this.addItem(e));

    this.queryMenu
      .on('rename')
      .subscribe((e:QueryMenuEvent) => this.renameItem(e));

    this.$scope.$watchCollection(
      () => this.$stateParams['query_id'],
      (queryId:string) => {
        this.currentQueryId = queryId;
        this.setSelectedState();
      });

    this.container.on('click', `.${QUERY_MENU_ITEM_TYPE}`, (event) => {
      if (LinkHandling.isClickedWithModifier(event)) {
        return true;
      }

      this.switchOrReload(jQuery(event.target));
      event.preventDefault();
      return false;
    });
  }

  private removeItem(e:QueryMenuEvent) {
    const item = this.findItem(e.queryId);
    this.$animate.leave(item.parent());
    this.setSelectedState();
  }

  private setSelectedState() {
    // Set WP menu to selected if no current query id set
    this.$element.toggleClass('selected', !this.currentQueryId);

    // Update all queries children
    const queries = this.container.find('.query-menu-item');
    queries.toggleClass('selected', false);
    if (this.currentQueryId) {
      queries.filter(`#wp-query-menu-item-${this.currentQueryId}`).addClass('selected');
    }
  }

  private renameItem(e:QueryMenuEvent) {
    this.findItem(e.queryId)
      .find('.menu-item--title')
      .text(e.label!);
  }

  private addItem(e:QueryMenuEvent) {
    const item = this.buildItem(e);
    const previous = this.previousMenuItem(e.label!);

    if (previous) {
      jQuery(item).insertAfter(previous);
    } else {
      this.container.append(item);
    }

    this.setSelectedState();
  }

  private buildItem(e:QueryMenuEvent) {
    const li = document.createElement('li');

    const link = document.createElement('a');
    link.id = `wp-query-menu-item-${e.queryId}`;
    link.classList.add(QUERY_MENU_ITEM_TYPE);
    link.dataset.queryId = e.queryId;

    const span = document.createElement('span');
    span.classList.add('menu-item--title', 'ellipsis');
    span.textContent = e.label!;

    link.appendChild(span);
    li.appendChild(link);

    return li;
  }

  private findItem(queryId:string) {
    return this.container.find(`#wp-query-menu-item-${queryId}`);
  }

  private switchOrReload(item:JQuery) {
    const queryId = item.data('queryId').toString();
    let opts = {reload: false};

    if (queryId === this.currentQueryId) {
      this.wpListChecksumService.clear();
      opts.reload = true;
    }

    this.$state.go(
      this.uiRouteStateName,
      {query_props: null, query_id: queryId },
      opts
    );
  }

  /**
   * previousMenuItem
   *
   * Returns the menu item within the factories's container that has a title
   * alphabetically before the provided title. The considered menu items have
   * the type (css class) this factory is responsible for.
   *
   * Params
   *  * title: The string used for comparing.
   */
  public previousMenuItem(title:string):ng.IAugmentedJQuery|null {
    const allItems = this.container.find('li');

    if (allItems.length === 0) {
      return null;
    }

    let previousElement = angular.element(allItems[allItems.length - 1]);
    let i = allItems.length - 2;

    for (i; i >= 0; i--) {
      if ((title > previousElement.find('a').attr('title')) ||
        (previousElement.find('.' + QUERY_MENU_ITEM_TYPE).length === 0)) {
        return previousElement;
      }
      else {
        previousElement = angular.element(allItems[i]);
      }
    }

    return previousElement;
  }
}

opUiComponentsModule.directive('wpQueryMenu', () => {
  return {
    restrict: 'A',
    scope: {},
    controller: WpQueryMenuController,
    controllerAs: '$ctrl',
    bindToController: true
  };
});
