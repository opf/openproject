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

interface Filter {
  [key:string]:{
    operator:string;
    values:string[];
  };
}

export default class ProjectController extends Controller {
  static targets = [
    'filterFormToggle',
    'filterForm',
    'filter',
    'addFilterSelect',
    'spacer',
    'descriptionToggle',
    'operator',
    'filterValueContainer',
    'filterValueSelect',
    'days',
    'singleDay',
    'simpleValue',
  ];

  declare readonly filterFormToggleTarget:HTMLButtonElement;
  declare readonly filterFormTarget:HTMLFormElement;
  declare readonly filterTargets:HTMLElement[];
  declare readonly addFilterSelectTarget:HTMLSelectElement;
  declare readonly spacerTarget:HTMLElement;
  declare readonly descriptionToggleTargets:HTMLAnchorElement[];
  declare readonly operatorTargets:HTMLSelectElement[];
  declare readonly filterValueContainerTargets:HTMLElement[];
  declare readonly filterValueSelectTargets:HTMLSelectElement[];
  declare readonly daysTargets:HTMLInputElement[];
  declare readonly singleDayTargets:HTMLInputElement[];
  declare readonly simpleValueTargets:HTMLInputElement[];

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

  sendForm() {
    const ajaxIndicator = document.querySelector('#ajax-indicator') as HTMLElement;
    ajaxIndicator.style.display = '';
    const filters = this.parseFilters();
    const orderParam = this.getUrlParameter('sortBy');

    let query = `?filters=${encodeURIComponent(JSON.stringify(filters))}`;

    if (orderParam) {
      query = `${query}&sortBy=${encodeURIComponent(orderParam)}`;
    }

    window.location.href = window.location.pathname + query;
  }

  private parseFilters() {
    const advancedFilters = this.filterTargets.filter((filter) => !filter.classList.contains('hidden'));
    const filters:Filter[] = [];

    advancedFilters.forEach((filter) => {
      const filterName = filter.getAttribute('filter-name');
      const filterType = filter.getAttribute('filter-type');

      if (filterName && filterType) {
        const parsedOperator = this.operatorTargets.find((operator) => operator.getAttribute('data-filter-name') === filterName)?.value;
        if (parsedOperator) {
          const parsedValue = this.parseFilterValue(filterName, filterType, parsedOperator);

          if (parsedValue) {
            const currentFilter:Filter = {
              [filterName]: { operator: parsedOperator, values: parsedValue as string[] },
            };
            filters.push(currentFilter);
          }
        }
      }
    });

    return filters;
  }

  private readonly operatorsWithoutValues = ['*', '!*', 't', 'w'];
  private readonly selectFilterTypes = ['list', 'list_all', 'list_optional'];

  private parseFilterValue(filterName:string, filterType:string, operator:string) {
    const valueBlock = this.filterValueContainerTargets.find((filterValueContainer) => filterValueContainer.getAttribute('data-filter-name') === filterName);

    if (valueBlock) {
      const checkbox = valueBlock.querySelector('input[type="checkbox"]') as HTMLInputElement;

      if (checkbox) {
        return [checkbox.checked ? 't' : 'f'];
      }

      if (this.operatorsWithoutValues.includes(operator)) {
        return [];
      }

      if (this.selectFilterTypes.includes(filterType)) {
        return this.parseSelectFilterValue(valueBlock, filterName);
      }

      if (['datetime_past', 'date'].includes(filterType)) {
        return this.parseDateFilterValue(valueBlock, filterName);
      }

      const value = this.simpleValueTargets.find((simpleValueInput) => simpleValueInput.getAttribute('data-filter-name') === filterName)?.value;

      if (value) {
        return [value];
      }

      return null;
    }

    return null;
  }

  private parseSelectFilterValue(valueBlock:HTMLElement, filterName:string) {
    let selectFields;

    if (valueBlock.classList.contains('multi-value')) {
      selectFields = this.filterValueSelectTargets.filter((selectField) => selectField.multiple && selectField.getAttribute('data-filter-name') === filterName);
    } else {
      selectFields = this.filterValueSelectTargets.filter((selectField) => !selectField.multiple && selectField.getAttribute('data-filter-name') === filterName);
    }

    const values = _.flatten(Array.from(selectFields).map((selectField:HTMLSelectElement) => Array.from(selectField.selectedOptions).map((option) => option.value)));

    if (values.length > 0) {
      return values;
    }

    return null;
  }

  private parseDateFilterValue(valueBlock:HTMLElement, filterName:string) {
    let value;

    if (valueBlock.classList.contains('days')) {
      const dateValue = this.daysTargets.find((daysField) => daysField.getAttribute('data-filter-name') === filterName)?.value;
      value = _.without([dateValue], '');
    } else if (valueBlock.classList.contains('on-date')) {
      const dateValue = this.singleDayTargets.find((dateInput) => dateInput.id === `on-date-value-${filterName}`)?.value;
      value = _.without([dateValue], '');
    } else if (valueBlock.classList.contains('between-dates')) {
      const fromValue = this.singleDayTargets.find((dateInput) => dateInput.id === `between-dates-from-value-${filterName}`)?.value;
      const toValue = this.singleDayTargets.find((dateInput) => dateInput.id === `between-dates-to-value-${filterName}`)?.value;
      value = [fromValue, toValue];
    }

    if (value && value.length > 0) {
      return value;
    }

    return null;
  }

  private getUrlParameter(sParam:string) {
    const sPageURL = decodeURIComponent(window.location.search.substring(1));
    const sURLVariables = sPageURL.split('&');

    for (let i = 0; i < sURLVariables.length; i++) {
      const sParameterName = sURLVariables[i].split('=');

      if (sParameterName[0] === sParam) {
        return sParameterName[1] === undefined ? 'true' : sParameterName[1];
      }
    }

    return null;
  }
}
