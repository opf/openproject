//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class TypeFormConfigurationController extends Controller {
  static services:ServiceKey[] = ['turboRequests', 'externalRelationQueryConfiguration'];

  static targets = ['groupsContainer', 'inactiveContainer'];

  declare readonly groupsContainerTarget:HTMLElement;
  declare readonly inactiveContainerTarget:HTMLElement;
  declare readonly hasInactiveContainerTarget:boolean;

  static values = {
    addGroupUrl: String,
    noFilterQuery: String,
  };

  declare readonly addGroupUrlValue:string;
  declare readonly noFilterQueryValue:string;

  declare services:Promise<PickedServices<'turboRequests'|'externalRelationQueryConfiguration'>>;

  private filterFrame?:number;

  initialize() {
    useAngularServices(this);
  }

  addQueryGroup(event:Event) {
    event.preventDefault();

    void this.openQueryEditor(this.noFilterQueryValue, (queryProps:unknown) => {
      void this.postNewGroup('query', queryProps);
    });
  }

  disconnect() {
    if (this.filterFrame !== undefined) {
      cancelAnimationFrame(this.filterFrame);
      this.filterFrame = undefined;
    }
  }

  confirmDiscardingEdit(event:Event) {
    if (!this.element.querySelector('[data-edit-mode="true"]')) {
      return;
    }

    if (!window.confirm(I18n.t('js.text_are_you_sure_to_cancel'))) {
      event.preventDefault();
    }
  }

  inactiveContainerTargetConnected() {
    this.applyInactiveFilter();
  }

  // A morph keeps the container connected and strips the classes the filter
  // set, so the target-connected hook above does not cover it.
  reapplyInactiveFilter(event:Event) {
    if (!this.hasInactiveContainerTarget || !(event.target instanceof Node)) {
      return;
    }

    if (!this.inactiveContainerTarget.contains(event.target) || this.filterFrame !== undefined) {
      return;
    }

    this.filterFrame = requestAnimationFrame(() => {
      this.filterFrame = undefined;
      this.applyInactiveFilter();
    });
  }

  editQuery(event:Event) {
    event.preventDefault();

    const group = (event.currentTarget as HTMLElement).closest<HTMLElement>('[data-group-key]');
    if (!group) return;

    void this.openQueryEditor(group.dataset.groupQuery ?? this.noFilterQueryValue, (queryProps:unknown) => {
      const url = group.dataset.updateQueryUrl;
      if (!url) {
        console.warn('Type form configuration group is missing its data-update-query-url; the query cannot be saved.', group);
        return;
      }

      void this.postQueryUpdate(url, queryProps).then((success) => {
        if (success) {
          group.dataset.groupQuery = JSON.stringify(queryProps);
        }
      });
    });
  }

  private applyInactiveFilter() {
    const filterListElement = this.element.querySelector<HTMLElement>('[data-controller~="filter--filter-list"]');
    if (!filterListElement) return;

    const filterListController = this.application.getControllerForElementAndIdentifier(filterListElement, 'filter--filter-list') as { filterLists:() => void }|null;
    filterListController?.filterLists();
  }

  private async postNewGroup(groupType:'attribute'|'query', queryProps?:unknown):Promise<void> {
    const { turboRequests } = await this.services;

    const body = new URLSearchParams({
      group_type: groupType,
    });

    if (queryProps) {
      body.set('query', JSON.stringify(queryProps));
    }

    await turboRequests.request(this.addGroupUrlValue, {
      method: 'POST',
      headers: {
        Accept: 'text/vnd.turbo-stream.html',
      },
      body,
    });
  }

  private async postQueryUpdate(url:string, queryProps:unknown):Promise<boolean> {
    const { turboRequests } = await this.services;

    await turboRequests.request(url, {
      method: 'PATCH',
      headers: {
        Accept: 'text/vnd.turbo-stream.html',
      },
      body: new URLSearchParams({
        query: JSON.stringify(queryProps),
      }),
    });

    return true;
  }

  private async openQueryEditor(queryJson:string, callback:(queryProps:unknown) => void) {
    const { externalRelationQueryConfiguration } = await this.services;

    const currentQuery = JSON.parse(queryJson) as unknown;
    const disabledTabs = {
      'display-settings': I18n.t('js.work_packages.table_configuration.embedded_tab_disabled'),
      timelines: I18n.t('js.work_packages.table_configuration.embedded_tab_disabled'),
    };

    externalRelationQueryConfiguration.show({
      currentQuery,
      callback,
      disabledTabs,
    });
  }
}
