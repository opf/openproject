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
import type { SelectPanelElement } from '@primer/view-components/app/components/primer/alpha/select_panel_element';
import { escapeFilterValue } from 'core-stimulus/helpers/filter-helpers';

export default class FilterSelectPanelController extends Controller<SelectPanelElement> {
  static targets = ['applyButton', 'clearButton'];

  static values = {
    filterKey: { type: String },
    baseUrl: { type: String }
  };

  declare readonly filterKeyValue:string;
  declare readonly baseUrlValue:string;
  declare readonly applyButtonTarget:HTMLButtonElement;
  declare readonly clearButtonTarget:HTMLButtonElement;
  declare searchParams:URLSearchParams;
  declare appliedIds:string[];

  connect() {
    this.searchParams = new URLSearchParams(window.location.search);
    this.appliedIds = this.parseIds(this.searchParams.get(this.filterKeyValue));
  }

  refreshButtons() {
    this.applyButtonTarget.disabled = this.selectedIds().join(',') == this.appliedIds.join(',');
    this.clearButtonTarget.disabled = this.selectedIds().length == 0;
  }

  revertOnClose() {
    this.element.items.forEach((item) => {
      const value = item.querySelector<HTMLElement>('.ActionListContent')?.dataset.value;
      if (value && this.appliedIds.includes(value)) {
        this.element.checkItem(item);
      } else {
        this.element.uncheckItem(item);
      }
    });
  }

  clear() {
    this.searchParams.delete(this.filterKeyValue);
    this.submitFilter();
  }

  apply() {
    if (this.selectedIds().length > 0) {
      this.searchParams.set(this.filterKeyValue, this.filterString());
    } else {
      this.searchParams.delete(this.filterKeyValue);
    }
    this.submitFilter();
  }

  private submitFilter() {
    const requestURL = new URL(this.baseUrlValue, window.location.origin);
    this.searchParams.forEach((value, key) => requestURL.searchParams.set(key, value));
    Turbo.visit(requestURL.href, { frame: 'backlogs_container', action: 'advance' });
  }

  private selectedIds():string[] {
    return [
      ...new Set(
        this.element
        .selectedItems
        .map((item) => item.value)
        .filter((value):value is string => value != null && value.length > 0)
      )
    ].sort();
  }

  private parseIds(param:string|null):string[] {
    if (param === null) return [];

    let parsed:unknown;
    try {
      parsed = JSON.parse(param);
    } catch {
      return [];
    }

    const ids = (Array.isArray(parsed) ? parsed : [parsed]) as unknown[];
    return [
      ...new Set(
        ids
          .filter((id) => typeof id === 'string' || typeof id === 'number')
          .map(String)
      )
    ].sort();
  }

  private filterString() {
    const filters = this.selectedIds().map(escapeFilterValue);
    return JSON.stringify(filters.length > 1 ? filters : filters[0]);
  }
}
