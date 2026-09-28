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
import { renderStreamMessage, visit } from '@hotwired/turbo';
import type { SelectPanelElement, SelectPanelItem } from '@primer/view-components/app/components/primer/alpha/select_panel_element';
import { debounce } from 'lodash-es';
import {
  hideElement,
  showElement,
} from 'core-app/shared/helpers/dom-helpers';
import { escapeFilterValue } from 'core-stimulus/helpers/filter-helpers';
import { PrimerMultiInputElement } from '@primer/view-components/app/lib/primer/forms/primer_multi_input';

interface PrimerTextFieldElement extends HTMLElement {
  inputElement:HTMLInputElement;
}

export interface InternalFilterValue {
  name:string;
  operator:string;
  value:string[];
}

type SerializedFilter = Record<string, { operator:string; values:unknown[] }>;

type FilterFunc<T> = (_value:T) => boolean;

export default class FilterSelectPanelController extends Controller<SelectPanelElement> {
  static targets = ['applyButton', 'clearButton'];

  declare readonly filterFormToggleTarget:HTMLButtonElement;
  // The filter button has 2 counters, one is displayed and the other is for screen readers.
  declare readonly hasFilterFormToggleTarget:boolean;

  static values = {
    displayFilters: { type: Boolean, default: false },
    filterKey: { type: String },
    baseUrl: { type: String }
  };

  declare displayFiltersValue:boolean;
  declare readonly filterKeyValue:string;
  declare readonly baseUrlValue:string;
  declare readonly turboFrameRequestValue:string;
  declare hasFilterFormTarget:boolean;
  declare readonly applyButtonTarget:HTMLButtonElement;
  declare readonly clearButtonTarget:HTMLButtonElement;
  declare searchParams:URLSearchParams;
  declare appliedIds:string[];

  initialize() {
  }

  connect() {
    this.searchParams = new URLSearchParams(window.location.search);

    const params = this.searchParams.get(this.filterKeyValue);
    if (params != null) {
      const filterValues = JSON.parse(params);
      this.appliedIds = [...new Set(Array.isArray(filterValues) ? filterValues : [filterValues])].sort();
    } else {
      this.appliedIds = [];
    }
  }

  disconnect() {
  }

  refreshButtons() {
    this.applyButtonTarget.disabled = this.selectedIds().join(",") == this.appliedIds.join(",");
    this.clearButtonTarget.disabled = this.selectedIds().length == 0;
  }

  revertOnClose() {
    this.element.items.forEach((item) => {
      const value = item.querySelector('.ActionListContent')?.getAttribute('data-value');
      if (value && this.appliedIds.includes(value)) {
        this.element.checkItem(item)
      } else {
        this.element.uncheckItem(item)
      }
    })
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

  private filterString() {
    const filters = this.selectedIds().map(escapeFilterValue);
    return JSON.stringify(filters.length > 1 ? filters : filters[0]);
  }
}
