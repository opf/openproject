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
import { renderStreamMessage, visit, type TurboBeforeMorphAttributeEvent } from '@hotwired/turbo';
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

// Marks a row the user added that holds no value yet. It is not part of any request, so a
// re-render of the form would hide it again; the morph guard keeps marked rows as they are.
const PENDING_ATTRIBUTE = 'data-filter-pending';

// Turbo's page snapshot keeps live control values, so a hidden row would otherwise still
// carry the draft the user typed and submit it the moment the filter is added again.
function resetControls(row:HTMLElement) {
  row.querySelectorAll<HTMLInputElement|HTMLSelectElement|HTMLTextAreaElement>('input, select, textarea').forEach((control) => {
    if (control instanceof HTMLSelectElement) {
      Array.from(control.options).forEach((option) => { option.selected = option.defaultSelected; });
    } else if (control instanceof HTMLInputElement && (control.type === 'checkbox' || control.type === 'radio')) {
      control.checked = control.defaultChecked;
    } else {
      control.value = control.defaultValue;
    }
  });
}

export default class FiltersFormController extends Controller {
  static targets = [
    'filterFormToggle',
    'filterForm',
    'simpleFilter',
    'filter',
    'addFilterSelect',
    'operator',
    'filterValueContainer',
    'days',
    'singleDay',
    'dateRange',
    'simpleValue',
    'filtersInput',
    'filterCount',
  ];

  declare readonly filterFormToggleTarget:HTMLButtonElement;
  // The filter button has 2 counters, one is displayed and the other is for screen readers.
  declare readonly filterCountTargets:HTMLElement[];
  declare readonly filterFormTarget:HTMLFormElement;
  declare readonly simpleFilterTargets:HTMLElement[];
  declare readonly filterTargets:HTMLElement[];
  declare readonly addFilterSelectTarget:HTMLSelectElement;
  declare readonly operatorTargets:HTMLSelectElement[];
  declare readonly filterValueContainerTargets:HTMLElement[];
  declare readonly daysTargets:HTMLInputElement[];
  declare readonly singleDayTargets:HTMLInputElement[];
  declare readonly dateRangeTargets:HTMLInputElement[];
  declare readonly simpleValueTargets:HTMLInputElement[];
  declare readonly filtersInputTarget:HTMLInputElement;

  declare readonly hasFilterFormToggleTarget:boolean;
  declare readonly hasFiltersInputTarget:boolean;

  static values = {
    displayFilters: { type: Boolean, default: false },
    outputFormat: { type: String, default: 'params' },
    turboStreamRequest: { type: Boolean, default: false },
    turboFrameRequest: String,
    clearButtonId: String,
    urlPathName: String,
    currentFilters: Array,
    resetParams: { type: Array, default: ['page'] },
  };

  declare displayFiltersValue:boolean;
  declare outputFormatValue:string;
  declare turboStreamRequestValue:boolean;
  declare readonly turboFrameRequestValue:string;
  declare readonly hasTurboFrameRequestValue:boolean;
  declare readonly clearButtonIdValue:string;
  declare urlPathNameValue:string;
  declare currentFiltersValue:SerializedFilter[];
  declare resetParamsValue:string[];
  declare hasFilterFormTarget:boolean;

  private formLoadedResolver:(() => void)|null = () => null;

  filterFormLoaded = new Promise<void>((resolve) => {
    this.formLoadedResolver = resolve;
  });

  private boundListener:() => void;
  private abortController?:AbortController;
  private sentFilters:string|null = null;

  initialize() {
    // Initialize runs anytime an element with a controller connected to the DOM for the first time
    this.boundListener = debounce(this.sendFormLive.bind(this), 300);
  }

  connect() {
    this.abortController = new AbortController();
    const { signal } = this.abortController;

    const clearButton = document.getElementById(this.clearButtonIdValue);
    clearButton?.addEventListener('click', (event) => this.clearInputWithButton(event), { signal });
    this.element.addEventListener('turbo:before-morph-attribute', this.keepPendingRows, { signal });

    // A restored page brings its markup back but not this controller's model, so a marker
    // already in the DOM here belongs to whoever was cached.
    this.pendingRows().forEach((row) => this.releasePendingRow(row, { hide: true }));
  }

  disconnect() {
    this.abortController?.abort();
  }

  addFilterSelectTargetConnected() {
    // This is used as an indicator that the filter form is loaded. Other targets could have been used
    // as well.
    if (this.formLoadedResolver) {
      this.formLoadedResolver();
      this.formLoadedResolver = null;
    }

    // Populate the hidden field with the current serialized filters so the
    // initial form state is submittable without any user interaction.
    if (this.hasFiltersInputTarget) {
      this.writeFiltersToHiddenInput();
    }
  }

  // Register and deregister change/input listeners on input elements to reload the page's frames on user input.
  // Using the target's methods rather than the shorter version in the controllers connect and disconnect function
  // as the filters themselves might be loaded later. If that is the case, they would not be known on connect.
  simpleValueTargetConnected(target:HTMLElement) {
    this.addChangeListener(target);
  }

  operatorTargetConnected(target:HTMLElement) {
    this.addChangeListener(target);
  }

  filterValueContainerTargetConnected(target:HTMLElement) {
    this.addChangeListener(target);
    const filterName = target.getAttribute('data-filter-name');
    if (filterName) {
      const operator = this.findTargetByName(filterName, this.operatorTargets);
      if (operator && this.operatorRequiresNoValue(operator)) {
        target.setAttribute('hidden', '');
      }
    }
  }

  daysTargetConnected(target:HTMLElement) {
    this.addChangeListener(target);
  }

  singleDayTargetConnected(target:HTMLElement) {
    this.addChangeListener(target);
    this.registerAngularPickerWithMultiInput(target, 'opce-basic-single-date-picker');
  }

  dateRangeTargetConnected(target:HTMLElement) {
    this.addChangeListener(target);
    this.registerAngularPickerWithMultiInput(target, 'opce-range-date-picker');
  }

  // angular_component_tag serialises @Input() bindings as JSON in data-* attributes, so the
  // Angular date picker wrapper's data-name holds a JSON-encoded value that primer-multi-input
  // cannot use to identify its child fields.  date_picker.html.erb therefore also sets
  // data-multi-input-name as a plain string with the intended field name.
  // This method is called when the Stimulus target connects, i.e. after Angular has already
  // bootstrapped the component and consumed its data-* attributes, so we can safely overwrite
  // data-name with the plain string from data-multi-input-name without interfering with Angular.
  // primer-multi-input.activateField() then uses data-name to show/hide the correct picker
  // when the filter operator changes.
  private registerAngularPickerWithMultiInput(target:HTMLElement, tagName:string) {
    const wrapper = target.closest<HTMLElement>(tagName);
    if (wrapper?.closest('primer-multi-input')) {
      const multiInputName = wrapper.getAttribute('data-multi-input-name');
      if (multiInputName) {
        wrapper.setAttribute('data-name', multiInputName);
      }
    }
  }

  simpleValueTargetDisconnected(target:HTMLElement) {
    this.removeChangeListener(target);
  }

  operatorTargetDisconnected(target:HTMLElement) {
    this.removeChangeListener(target);
  }

  filterValueContainerTargetDisconnected(target:HTMLElement) {
    this.removeChangeListener(target);
  }

  daysTargetDisconnected(target:HTMLElement) {
    this.removeChangeListener(target);
  }

  singleDayTargetDisconnected(target:HTMLElement) {
    this.removeChangeListener(target);
  }

  dateRangeTargetDisconnected(target:HTMLElement) {
    this.removeChangeListener(target);
  }

  filterFormTargetConnected()  {
    // Didn't really change, but we need to ensure that the visibility of the target is correct.
    // This is caused by there first being a skeleton form, which allows the user to already
    // toggle the visibility.
    this.displayFiltersValueChanged();
  }


  toggleDisplayFilters() {
    this.displayFiltersValue = !this.displayFiltersValue;
  }

  showDisplayFilters() {
    this.displayFiltersValue = true;
  }

  displayFiltersValueChanged() {
    if (this.hasFilterFormToggleTarget){
      this.toggleButtonActive();
      this.toggleFilterFormVisible();
    }
  }

  toggleButtonActive() {
    if (this.displayFiltersValue) {
      this.filterFormToggleTarget.setAttribute('aria-pressed', 'true');
    } else {
      this.filterFormToggleTarget.removeAttribute('aria-pressed');
    }
  }

  toggleFilterFormVisible() {
    if (this.hasFilterFormTarget) {
      this.filterFormTarget.classList.toggle('-expanded', this.displayFiltersValue);
    }
  }

  private get liveUpdatesEnabled():boolean {
    return this.turboStreamRequestValue || this.hasTurboFrameRequestValue || this.hasFiltersInputTarget;
  }

  private addChangeListener(target:HTMLElement) {
    if (!this.liveUpdatesEnabled) { return; }

    if (target instanceof HTMLInputElement) {
      target.addEventListener('input', this.boundListener);
    } else {
      target.addEventListener('change', this.boundListener);
    }
  }

  private removeChangeListener(target:HTMLElement) {
    if (!this.liveUpdatesEnabled) { return; }

    if (target instanceof HTMLInputElement) {
      target.removeEventListener('input', this.boundListener);
    } else {
      target.removeEventListener('change', this.boundListener);
    }
  }

  addFilter(event:Event) {
    const filterName = (event.target as HTMLSelectElement).value;
    this.addFilterByName(filterName);
  }

  addFilterByName(filterName:string) {
    const selectedFilter = this.findTargetByName(filterName, this.filterTargets);
    if (selectedFilter) {
      selectedFilter.removeAttribute('hidden');
      selectedFilter.setAttribute(PENDING_ATTRIBUTE, '');
    }
    this.setFilterOptionTaken(filterName, true);
    this.addFilterSelectTarget.selectedIndex = 0;

    this.focusFilterValueIfPossible(selectedFilter);

    this.sendFormLive();
  }

  focusFilterValueIfPossible(element:undefined|HTMLElement) {
    const filterName = element?.getAttribute('data-filter-name');
    if (!filterName) return;

    const operator = this.findTargetByName(filterName, this.operatorTargets);
    const container = this.findTargetByName(filterName, this.filterValueContainerTargets);
    const canFocus = (candidate:HTMLElement) => candidate.isConnected
      && !candidate.matches(':disabled, input[type="hidden"]')
      && !candidate.closest('[hidden], [inert]')
      && candidate.checkVisibility({ visibilityProperty: true });

    let target:HTMLElement|undefined;
    if (operator && this.operatorRequiresNoValue(operator)) {
      target = canFocus(operator) ? operator : undefined;
    } else if (container) {
      const controls = 'input, select, textarea, button';
      const candidates = [
        ...container.querySelectorAll<HTMLElement>('ng-select input'),
        ...container.querySelectorAll<HTMLElement>('button[aria-current="true"]'),
        ...(container.matches(controls) ? [container] : []),
        ...container.querySelectorAll<HTMLElement>(controls),
      ];
      target = candidates.find(canFocus);
    }

    if (target) {
      const destination = target;
      window.setTimeout(() => {
        if (canFocus(destination)) destination.focus();
      }, 250);
    }
  }

  removeFilter({ params: { filterName } }:{ params:{ filterName:string } }) {
    const filterToRemove = this.findTargetByName(filterName, this.filterTargets);
    if (filterToRemove) {
      filterToRemove.setAttribute('hidden', '');
      filterToRemove.removeAttribute(PENDING_ATTRIBUTE);
    }
    this.setFilterOptionTaken(filterName, false);

    this.sendFormLive();
  }

  private setFilterOptionTaken(filterName:string, taken:boolean) {
    const option = Array.from(this.addFilterSelectTarget.options).find((candidate) => candidate.value === filterName);
    if (option) {
      option.disabled = taken;
    }
  }

  private pendingRows():HTMLElement[] {
    return this.filterTargets.filter((row) => row.hasAttribute(PENDING_ATTRIBUTE));
  }

  private releaseSubmittedPendingRows() {
    const submitted = new Set(this.parseFilters().map((filter) => filter.name));
    this.pendingRows()
      .filter((row) => submitted.has(row.dataset.filterName!))
      .forEach((row) => this.releasePendingRow(row, { hide: false }));
  }

  private releasePendingRow(row:HTMLElement, { hide }:{ hide:boolean }) {
    row.removeAttribute(PENDING_ATTRIBUTE);
    if (hide) {
      row.setAttribute('hidden', '');
      this.setFilterOptionTaken(row.dataset.filterName!, false);
      resetControls(row);
      this.showValueForOperator(row.dataset.filterName!);
    }
  }

  // Which picker is shown, and whether the value container is shown at all, follows the
  // operator through attributes that a reset of control values leaves untouched.
  private showValueForOperator(filterName:string) {
    const operator = this.findTargetByName(filterName, this.operatorTargets);
    if (operator) {
      this.setValueVisibility({ target: operator, params: { filterName } });
    }
  }

  private readonly keepPendingRows = (event:TurboBeforeMorphAttributeEvent) => {
    const { attributeName } = event.detail;
    const target = event.target as HTMLElement;

    const isPendingRow = this.filterTargets.includes(target) && target.hasAttribute(PENDING_ATTRIBUTE);
    const keepsRow = isPendingRow && (attributeName === 'hidden' || attributeName === PENDING_ATTRIBUTE);
    const keepsOptionTaken = attributeName === 'disabled'
      && target instanceof HTMLOptionElement
      && target.closest('select') === this.addFilterSelectTarget
      && this.pendingRows().some((row) => row.dataset.filterName === target.value);

    if (keepsRow || keepsOptionTaken) {
      event.preventDefault();
    }
  };

  clearInputWithButton(event:MouseEvent) {
    // Primer does not trigger an input event when clearing the value of the input field unless
    // it is focused. This handler will find the sibling input of the clear button inside the
    // PrimerTextField and triggers the input in order to notify the auto-reloading filter mechanism.
    const element = event.currentTarget as HTMLElement;
    const primerTextField = element.closest<PrimerTextFieldElement>('primer-text-field')!;
    const inputElement = primerTextField.inputElement;

    const inputEvent = new Event('input', {
      bubbles: true,
      cancelable: true,
    });
    inputElement.dispatchEvent(inputEvent);
  }

  private updateFilterCounter() {
    const filterCount = this.parseFilters().length;
    this.filterCountTargets.forEach((counter) => {
      counter.textContent = `${filterCount}`;
      counter.hidden = filterCount === 0;
    });
  }

  private readonly daysOperators = ['>t-', '<t-', 't-', '<t+', '>t+', 't+'];
  private readonly onDateOperator = '=d';
  private readonly betweenDatesOperator = '<>d';

  // Whether the operator currently selected in `operatorElement` declares
  // itself value-less. Driven by the `data-no-value` attribute that
  // `Filters::Inputs::BaseFilterForm#add_operator` emits on each `<option>`
  // whose `Operator.requires_value?` is false — keeps the symbol list in
  // one place (Ruby) instead of duplicating it here.
  private operatorRequiresNoValue(operatorElement:HTMLSelectElement):boolean {
    return operatorElement.selectedOptions[0]?.hasAttribute('data-no-value') ?? false;
  }

  setValueVisibility({ target, params: { filterName } }:{ target:HTMLSelectElement, params:{ filterName:string } }) {
    const selectedOperator = target.value;
    const valueContainer = this.findTargetByName(filterName, this.filterValueContainerTargets);
    if (valueContainer) {
      if (this.operatorRequiresNoValue(target)) {
        valueContainer.setAttribute('hidden', '');
      } else {
        valueContainer.removeAttribute('hidden');
      }

      const multiInput = valueContainer.querySelector<PrimerMultiInputElement>('primer-multi-input');
      if (this.daysOperators.includes(selectedOperator)) {
        multiInput?.activateField('days');
      } else if (selectedOperator === this.onDateOperator) {
        multiInput?.activateField('singleDay');
      } else if (selectedOperator === this.betweenDatesOperator) {
        multiInput?.activateField('dateRange');
      }
    }
  }

  serializedFiltersWith(additions:InternalFilterValue[] = [], { except }:{ except?:string } = {}):string {
    const filters = this.currentFilters().filter((filter) => filter.name !== except);
    return this.buildFiltersParam([...filters, ...additions]);
  }

  private currentFilters():InternalFilterValue[] {
    // Owned filters are filters that we see in this form,
    // and those we want to update with the actual value present in the filter form
    const ownedFilterNames = new Set(
      [...this.simpleFilterTargets, ...this.filterTargets]
        .map((filter) => filter.getAttribute('data-filter-name'))
        .filter((name):name is string => name !== null),
    );

    // Unowned filter might be additional information, keys, params that we do not know in this form
    // we will simply reflect them again so they do not change.
    const unownedFilters = this.currentFiltersValue.flatMap((filter) => (
      Object.entries(filter).map(([name, options]) => ({
        name,
        operator: options.operator,
        value: options.values.map(String),
      }))
    )).filter((filter) => !ownedFilterNames.has(filter.name));

    return [...unownedFilters, ...this.parseFilters()];
  }

  // Public entrypoint for the autocomplete/list filter hidden fields
  autocompleteSendForm() {
    this.sendFormLive();
  }

  // Only for change/input listeners that stay bound regardless of whether live updates are
  // enabled (e.g. the "add filter"/"remove filter" buttons). The plain form submit action
  // must always call sendForm() directly.
  private sendFormLive() {
    if (this.liveUpdatesEnabled) {
      this.updateFilterCounter();
      this.sendForm();
    }
  }

  sendForm() {
    this.releaseSubmittedPendingRows();

    // When we want the filter content to be written to a hidden input, do this.
    // When we do not also want the turbo requests, we can exit early here. Otherwise the automatic redirect
    // would also be triggered. We do not want this in the case where we use the filter input in another form
    if (this.hasFiltersInputTarget) {
      this.writeFiltersToHiddenInput();

      if (!this.turboStreamRequestValue) {
        return;
      }
    }

    const params = new URLSearchParams(window.location.search);
    const newFilters = this.buildFiltersParam(this.currentFilters());

    if (newFilters === (this.sentFilters ?? params.get('filters') ?? '')) {
      // Some fields may be triggered via the input event and the change event too.
      // This early return will prevent firing request when the filter params are not changed.
      return;
    }

    this.resetParamsValue.forEach((parameter) => params.delete(parameter));

    if (newFilters) {
      params.set('filters', newFilters);
    } else {
      params.delete('filters');
    }

    const pathName = this.urlPathNameValue || window.location.pathname;
    const search = params.toString();
    const url = `${pathName}${search ? `?${search}` : ''}`;
    const browserUrl = `${window.location.pathname}${search ? `?${search}` : ''}${window.location.hash}`;

    if (this.hasTurboFrameRequestValue) {
      // Turbo Drive shows its own progress bar for visits, so there is no need to
      // toggle the global loading indicator here as the other branches below do.
      visit(url, { frame: this.turboFrameRequestValue, action: 'advance' });
      return;
    }

    const loadingIndicator = document.querySelector<HTMLElement>('#global-loading-indicator')!;
    showElement(loadingIndicator);

    if (this.turboStreamRequestValue) {
      const previousFilters = this.sentFilters;
      this.sentFilters = newFilters;

      fetch(url, {
        headers: {
          Accept: 'text/vnd.turbo-stream.html',
        },
      })
        .then((response:Response) => response.text())
        .then((html:string) => {
          renderStreamMessage(html);
          if (this.sentFilters === newFilters) {
            window.history.replaceState(window.history.state, '', browserUrl);
          }
          hideElement(loadingIndicator);
        })
        .catch((error:Error) => {
          this.sentFilters = previousFilters;
          console.error('Error:', error);
          hideElement(loadingIndicator);
        });
    } else {
      window.location.href = url;
    }
  }

  private writeFiltersToHiddenInput() {
    this.filtersInputTarget.value = this.buildFiltersParam(this.currentFilters());
  }

  private parseFilters():InternalFilterValue[] {
    const filters:InternalFilterValue[] = [];
    filters.push(...this.parseSimpleFilters());
    filters.push(...this.parseAdvancedFilters());
    return filters;
  }

  private parseSimpleFilters():InternalFilterValue[] {
    const simpleFilters = this.simpleFilterTargets;
    const filters:InternalFilterValue[] = [];

    simpleFilters.forEach((filter) => {
      const name = filter.getAttribute('data-filter-name');
      const type = filter.getAttribute('data-filter-type');
      const operator = filter.getAttribute('data-filter-operator');
      if (name && type && operator) {
        // Quick filters carry an operator that always requires a value
        // (the inline search input).
        const value = this.parseFilterValue(filter, name, type, operator, false) as string[]|null;

        if (value) {
          filters.push({ name, operator, value });
        }
      }
    });
    return filters;
  }

  private parseAdvancedFilters():InternalFilterValue[] {
    const advancedFilters = this.filterTargets.filter((filter) => !filter.hasAttribute('hidden'));
    const filters:InternalFilterValue[] = [];

    advancedFilters.forEach((filter) => {
      const filterName = filter.getAttribute('data-filter-name')!;
      const filterType = filter.getAttribute('data-filter-type');
      const operatorTarget = this.findTargetByName(filterName, this.operatorTargets);
      const parsedOperator = operatorTarget?.value;
      const valueContainer = this.findTargetByName(filterName, this.filterValueContainerTargets);

      if (valueContainer && filterName && filterType && parsedOperator && operatorTarget) {
        const requiresNoValue = this.operatorRequiresNoValue(operatorTarget);
        const parsedValue = this.parseFilterValue(valueContainer, filterName, filterType, parsedOperator, requiresNoValue) as string[]|null;

        if (parsedValue) {
          filters.push({ name: filterName, operator: parsedOperator, value: parsedValue });
        }
      }
    });

    return filters;
  }

  private buildFilterString(filter:InternalFilterValue) {
    const valuesString = filter.value.length > 1 ? `[${filter.value.map((v) => `"${escapeFilterValue(v)}"`).join(',')}]` : `"${escapeFilterValue(filter.value[0])}"`;

    return `${filter.name} ${filter.operator} ${valuesString}`;
  }

  private buildFilterJSON(filter:InternalFilterValue) {
    return { [filter.name]: { operator: filter.operator, values: filter.value } };
  }

  private buildFiltersParam(filters:InternalFilterValue[]):string {
    if (this.outputFormatValue === 'json') {
      return JSON.stringify(filters.map((filter) => this.buildFilterJSON(filter)));
    }
    return filters.map((filter) => this.buildFilterString(filter)).join('&');
  }

  private readonly dateFilterTypes = ['datetime_past', 'date'];

  private parseFilterValue(valueContainer:HTMLElement, filterName:string, filterType:string, operator:string, requiresNoValue:boolean) {
    const checkbox = valueContainer.querySelector<HTMLInputElement>('input[type="checkbox"]');

    if (checkbox) {
      return [checkbox.checked ? 't' : 'f'];
    }

    if (requiresNoValue) {
      return [];
    }

    if (valueContainer.dataset.filterAutocomplete === 'true') {
      const selected = valueContainer.querySelector<HTMLInputElement>('input[name="value"]')?.value ?? '';
      const values = selected.split(',').filter((value) => value !== '');
      return values.length > 0 ? values : null;
    }

    if (this.dateFilterTypes.includes(filterType)) {
      return this.parseDateFilterValue(valueContainer, filterName);
    }

    const hiddenField = valueContainer.querySelector<HTMLInputElement>('input[type="hidden"]');

    if (hiddenField) {
      return hiddenField.value ? [hiddenField.value] : null;
    }

    const value = this.findTargetByName(filterName, this.simpleValueTargets)?.value;

    if (value && value.length > 0) {
      return [value];
    }
    return null;
  }

  private parseDateFilterValue(_valueContainer:HTMLElement, filterName:string) {
    let value;
    const operator = this.findTargetByName(filterName, this.operatorTargets)?.value;

    if (operator && this.daysOperators.includes(operator)) {
      const dateValue = this.findTargetByName(filterName, this.daysTargets)?.value;

      value = [dateValue].filter((v) => v !== '');
    } else if (operator === this.onDateOperator) {
      const dateValue = this.findTargetById(filterName, this.singleDayTargets)?.value;

      value = [dateValue].filter((v) => v !== '');
    } else if (operator === this.betweenDatesOperator) {
      // The range picker renders an empty range as "-" (see Filters::Inputs::DateForm#between_dates_div).
      const rangeValue = this.findTargetById(filterName, this.dateRangeTargets)?.value ?? '';
      const [fromValue = '', toValue = ''] = rangeValue === '-' ? [] : rangeValue.split(' - ');

      value = fromValue === '' && toValue === '' ? [] : [fromValue, toValue];
    }
    if (value && value.length > 0) {
      return value;
    }
    return null;
  }

  private findTargetByName<T extends HTMLElement>(
    filterName:string,
    targets:T[],
    targetFilter?:FilterFunc<T>,
  ):T | undefined {
    return this.findTargetBy(
      filterName,
      (target:T) => target.getAttribute('data-filter-name'),
      targets,
      targetFilter,
    );
  }

  private findTargetById<T extends HTMLElement>(
    filterName:string,
    targets:T[],
    targetFilter?:FilterFunc<T>,
  ):T | undefined {
    return this.findTargetBy(filterName, (target:T) => target.id, targets, targetFilter);
  }

  private findTargetBy<T extends HTMLElement>(
    attributeValue:string,
    attributeGetter:(_target:T) => string | null,
    targets:T[],
    targetFilter?:FilterFunc<T>,
  ):T | undefined {
    return targets.find((target) => {
      return attributeGetter(target) === attributeValue && (!targetFilter || targetFilter(target));
    });
  }
}
