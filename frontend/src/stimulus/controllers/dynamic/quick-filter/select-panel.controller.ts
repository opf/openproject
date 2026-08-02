/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import { visit } from '@hotwired/turbo';
import type { SelectPanelElement } from '@primer/view-components/app/components/primer/alpha/select_panel_element';
import type FiltersFormController from '../filter/filters-form.controller';
import type { InternalFilterValue } from '../filter/filters-form.controller';

type FilterHash = Record<string, { operator:string; values:string[] }>;

export default class SelectPanelQuickFilterController extends Controller {
  static values = {
    baseUrl: String,
    filterKey: String,
    operator: { type: String, default: '=' },
  };

  declare baseUrlValue:string;
  declare filterKeyValue:string;
  declare operatorValue:string;

  clear() {
    this.visitWith([]);
  }

  apply(event:Event) {
    // Prevent updating dynamic label before the page reloads anyway to stop flickering
    event.stopPropagation();

    const panel = this.element.querySelector<SelectPanelElement>('select-panel');
    if (!panel) return;

    const selectedValues = panel.selectedItems
      .map((item) => item.value)
      .filter((v):v is string => v != null && v.length > 0);

    this.visitWith(selectedValues);
  }

  private visitWith(selectedValues:string[]) {
    const params = new URLSearchParams(window.location.search);
    params.delete('page');

    const filters = this.serializedFilters(selectedValues);
    if (filters) {
      params.set('filters', filters);
    } else {
      params.delete('filters');
    }

    const { pathname } = new URL(this.baseUrlValue, window.location.origin);
    visit(`${pathname}?${params.toString()}`);
  }

  // The filters form is the single source of truth for the current filter state
  // (its DOM always reflects both the committed and pending input from the user).
  // We serialize it as it's the correct state to look for.
  private serializedFilters(selectedValues:string[]):string {
    const additions:InternalFilterValue[] = selectedValues.length > 0
      ? [{ name: this.filterKeyValue, operator: this.operatorValue, value: selectedValues }]
      : [];

    const form = this.filtersForm;
    if (form) {
      return form.serializedFiltersWith(additions, { except: this.filterKeyValue });
    }

    return this.fallbackSerializedFilters(additions);
  }

  private get filtersForm():FiltersFormController|null {
    const root = this.element.closest<HTMLElement>('[data-controller~="filter--filters-form"]');
    if (!root) {
      return null;
    }

    return this.application
      .getControllerForElementAndIdentifier(root, 'filter--filters-form') as FiltersFormController|null;
  }

  // When the panel is not found in the form, we try to add the current state back to
  // the filter URL we're building to ensure they are not dropped.
  private fallbackSerializedFilters(additions:InternalFilterValue[]):string {
    const raw = new URL(window.location.href).searchParams.get('filters');
    let current:FilterHash[] = [];
    if (raw) {
      try {
        current = (JSON.parse(raw) as FilterHash[])
          .filter((filter) => Object.keys(filter)[0] !== this.filterKeyValue);
      } catch {
        console.error('Failed to parse JSON filter set from URL params');
      }
    }

    const added = additions.map((f) => ({ [f.name]: { operator: f.operator, values: f.value } }));
    const filters = [...current, ...added];

    return filters.length > 0 ? JSON.stringify(filters) : '';
  }
}
