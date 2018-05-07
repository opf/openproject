//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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
//++

import {Inject, Injectable} from '@angular/core';
import {StateService, Transition, TransitionService} from '@uirouter/core';
import {$stateToken, I18nToken} from 'core-app/angular4-transition-utils';
import {LinkHandling} from 'core-components/common/link-handling/link-handling';
import {WorkPackagesListChecksumService} from 'core-components/wp-list/wp-list-checksum.service';
import {Title} from '@angular/platform-browser';
import {OpTitleService} from 'core-components/html/op-title.service';

export const QUERY_MENU_ITEM_TYPE = 'query-menu-item';

export type QueryMenuEvent = {
  event:'add' | 'remove' | 'rename';
  queryId:string;
  path?:string;
  label?:string;
};

@Injectable()
export class QueryMenuService {

  private currentQueryId:string|null = null;
  private uiRouteStateName = 'work-packages.list';
  private container:JQuery;

  constructor(@Inject($stateToken) readonly $state:StateService,
              @Inject(I18nToken) readonly I18n:op.I18n,
               readonly titleService:OpTitleService,
               readonly $transitions:TransitionService,
               readonly wpListChecksumService:WorkPackagesListChecksumService) {

    this.$transitions.onStart({}, (transition:Transition)  => {
      const queryId = transition.params('to').query_id;

      // Update query menu and title when either
      // the query menu id changed
      const queryIdChanged = this.currentQueryId !== queryId;
      // we're moving to the work-packges.list state
      const movingToWPList = transition.to().name === 'work-packages.list';
      if (movingToWPList || queryIdChanged) {
        this.onQueryIdChanged(queryId);
      }
    });

    this.initialize();

    this.container.on('click', `.${QUERY_MENU_ITEM_TYPE}`, (event) => {
      if (LinkHandling.isClickedWithModifier(event) || LinkHandling.isOutsideAngular()) {
        return true;
      }

      this.switchOrReload(jQuery(event.target));
      event.preventDefault();
      return false;
    });

  }

  public initialize() {
    this.container = jQuery('#main-menu-work-packages').parent().find('ul.menu-children');
    this.onQueryIdChanged(this.$state.params['query_id']);
  }

  /**
   * Add a query menu item
   */
  public add(name:string, path:string, queryId:string) {
    const item = this.buildItem(queryId, name);
    const previous = this.previousMenuItem(name);

    if (previous) {
      jQuery(item).insertAfter(previous);
    } else {
      this.container.append(item);
    }

    this.setSelectedState();
  }

  public rename(queryId:string, name:string) {
    this.findItem(queryId)
      .find('.menu-item--title')
      .text(name);
  }

  public remove(queryId:string) {
    this.removeItem(queryId);
  }

  public onQueryIdChanged(queryId:string|null) {
    this.currentQueryId = queryId;
    this.setSelectedState();
  }

  private removeItem(queryId:string) {
    const item = this.findItem(queryId);
    item.remove();
    this.setSelectedState();
  }

  private setSelectedState() {
    // Set WP menu to selected if no current query id set
    if (this.currentQueryId) {
      jQuery('#main-menu-work-packages').removeClass('selected');
    }

    // Update all queries children
    const queries = this.container.find('.query-menu-item');
    queries.toggleClass('selected', false);

    if (this.currentQueryId) {
      let current = queries.filter(`#wp-query-menu-item-${this.currentQueryId}`)
      current.addClass('selected');

      // Set the page title
      this.titleService.setFirstPart(current.text());
    }

  }

  private buildItem(queryId:string, name:string) {
    const li = document.createElement('li');

    const link = document.createElement('a');
    link.id = `wp-query-menu-item-${queryId}`;
    link.classList.add(QUERY_MENU_ITEM_TYPE);
    link.dataset.queryId = queryId;

    const span = document.createElement('span');
    span.classList.add('menu-item--title', 'ellipsis');
    span.textContent = name;

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
