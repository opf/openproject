/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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
 *
 */

import { Controller } from '@hotwired/stimulus';

export default class ProjectController extends Controller {
  static targets=[
    'filterFormToggle',
    'filterForm',
    'filter',
    'addFilterSelect',
    'spacer',
    'descriptionToggle',
  ];

  declare readonly filterFormToggleTarget:HTMLButtonElement;
  declare readonly filterFormTarget:HTMLFormElement;
  declare readonly filterTargets:HTMLElement[];
  declare readonly addFilterSelectTarget:HTMLSelectElement;
  declare readonly spacerTarget:HTMLElement;
  declare readonly descriptionToggleTargets:HTMLAnchorElement[];

  connect() {
    // console.log('Project Controller Connected');
  }

  toggleFilterForm() {
    this.filterFormToggleTarget.classList.toggle('-active');
    this.filterFormTarget.classList.toggle('-expanded');
  }

  toggleMultiSelect(event:Event) {
    const valueSelector = (event.target as HTMLElement).closest('.advanced-filters--filter-value') as HTMLElement;
    const singleSelect = valueSelector.querySelector('.single-select select') as HTMLSelectElement;
    const multiSelect = valueSelector.querySelector('.multi-select select') as HTMLSelectElement;

    if (valueSelector.classList.contains('multi-value')) {
      const valueToSelect = this.getValueToSelect(multiSelect);
      this.setSelectOptions(singleSelect, valueToSelect);
    } else {
      const valueToSelect = this.getValueToSelect(singleSelect);
      this.setSelectOptions(multiSelect, valueToSelect);
    }

    valueSelector.classList.toggle('multi-value');
  }

  private getValueToSelect(selectElement:HTMLSelectElement) {
    return selectElement.selectedOptions[0]?.value;
  }

  private setSelectOptions(selectElement:HTMLSelectElement, selectedValue:string) {
    Array.from(selectElement.options).forEach((option) => {
      option.selected = option.value === selectedValue;
    });
  }

  addFilter(event:Event) {
    const selectedFilterName = (event.target as HTMLSelectElement).value;
    const selectedFilter = this.filterTargets.find((filter) => {
      const filterName = filter.getAttribute('filter-name');
      return filterName === selectedFilterName;
    });
    if (selectedFilter) {
      selectedFilter.classList.remove('hidden');
    }

    this.disableSelection();
    this.reselectPlaceholderOption();
    this.setSpacerVisibility();
  }

  private disableSelection() {
    this.addFilterSelectTarget.selectedOptions[0].setAttribute('disabled', 'disabled');
  }

  private reselectPlaceholderOption() {
    this.addFilterSelectTarget.options[0].setAttribute('selected', 'selected');
  }

  removeFilter({ params: { filterName } }:{ params:{ filterName:string } }) {
    const filterToRemove = this.filterTargets.find((filter) => filter.getAttribute('filter-name') === filterName);
    filterToRemove?.classList.add('hidden');

    const selectOptions = Array.from(this.addFilterSelectTarget.options);
    const removedFilterOption = selectOptions.find((option) => option.value === filterName);
    removedFilterOption?.removeAttribute('disabled');

    this.setSpacerVisibility();
  }

  private setSpacerVisibility() {
    if (this.anyFiltersStillVisible()) {
      this.spacerTarget.classList.remove('hidden');
    } else {
      this.spacerTarget.classList.add('hidden');
    }
  }

  private anyFiltersStillVisible() {
    return this.filterTargets.some((filter) => !filter.classList.contains('hidden'));
  }

  private readonly daysOperators = ['>t-', '<t-', 't-', '<t+', '>t+', 't+'];
  private readonly onDateOperator = '=d';
  private readonly betweenDatesOperator = '<>d';

  setValueVisibility({ target, params: { filterName } }:{ target:HTMLSelectElement, params:{ filterName:string } }) {
    const selectedOperator = target.value;
    const currentFilter = this.filterTargets.find((filter) => filter.getAttribute('filter-name') === filterName);
    const filterValue = currentFilter?.querySelector('.advanced-filters--filter-value');
    if (filterValue) {
      if (['*', '!*', 't', 'w'].includes(selectedOperator)) {
        filterValue.classList.add('hidden');
      } else {
        filterValue.classList.remove('hidden');
      }

      if (this.daysOperators.includes(selectedOperator)) {
        filterValue.classList.add('days');
        filterValue.classList.remove('on-date');
        filterValue.classList.remove('between-dates');
      } else if (selectedOperator === this.onDateOperator) {
        filterValue.classList.add('on-date');
        filterValue.classList.remove('days');
        filterValue.classList.remove('between-dates');
      } else if (selectedOperator === this.betweenDatesOperator) {
        filterValue.classList.add('between-dates');
        filterValue.classList.remove('days');
        filterValue.classList.remove('on-date');
      }
    }
  }

  toggleDescription({ target }:{ target:HTMLAnchorElement }) {
    const toggledTrigger = target;
    const otherTrigger = this.descriptionToggleTargets.find((trigger) => trigger !== toggledTrigger);
    const clickedRow = toggledTrigger.closest('.project') as HTMLElement;
    const descriptionRow = clickedRow.nextElementSibling as HTMLElement;

    if (clickedRow && descriptionRow) {
      clickedRow.classList.toggle('-no-highlighting');
      clickedRow.classList.toggle('-expanded');
      descriptionRow.classList.toggle('-expanded');

      this.setAriaLive(descriptionRow);
    }

    otherTrigger?.focus();
  }

  private setAriaLive(descriptionRow:HTMLElement) {
    if (descriptionRow.classList.contains('-expanded')) {
      descriptionRow.setAttribute('aria-live', 'polite');
    } else {
      descriptionRow.removeAttribute('aria-live');
    }
  }
}
