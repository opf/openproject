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
import { FetchRequestError, post, ValidationError } from 'core-stimulus/helpers/request-helpers';
import dragula from 'dragula';
import jQuery from 'jquery';
import 'core-app/core/setup-legacy/init-jquery';
import 'tablesorter';
import { ensureId } from 'core-app/shared/helpers/dom-helpers';

declare global {
  interface Window {
    global_prefix?:string;
  }
}

interface ShowFilterOptions {
  callback_func?:() => void;
  slowly?:boolean;
  show_filter?:boolean;
  hide_only?:boolean;
  insert_after?:HTMLElement;
}

interface IFilters {
  loadAvailableValuesForFilter:(filterName:string, callbackFunc:() => void) => void;
  add_filter:(filterName:string) => void;
  clear:() => void;
  exists:(filter:string) => boolean;
  operator_changed:(field:string, select:JQuery) => void;
  remove_filter:(field:string, hideOnly?:boolean) => void;
  select_option_enabled:(box:JQuery, value:string, state:boolean) => void;
  select_values:(selectBox:JQuery, valuesToSelect:string[]) => void;
  toggle_multi_select:(select:JQuery) => void;
  value_changed:(field:string) => void;
}

interface IGroupBys {
  group_by_container_ids:() => string[];
  initialize_drag_and_drop_areas:() => void;
  add_group_by:(field:string, caption:string, container:JQuery) => void;
  add_group_by_from_select:(select:HTMLSelectElement) => void;
  clear:() => void;
  create_group_by:(field:string, caption:string) => JQuery;
  exists:(groupByName:string) => boolean;
}

interface IControls {
  attach_settings_callback:(element:JQuery, callback:(response:string) => void) => void;
  clear_query:(e:Event) => void;
  observe_click:(elementId:string, callback:(e:Event) => void) => void;
  update_result_table:(response:string) => void;
  toggle_delete_form:(e:Event) => void;
  toggle_save_as_form:(e:Event) => void;
}

interface IRestoreQuery {
  restore_group_bys:() => void;
  restore_filters:() => void;
}

export default class PageController extends Controller {
  private filters!:IFilters;
  private groupBys!:IGroupBys;
  private controls!:IControls;
  private restoreQueryModule!:IRestoreQuery;

  connect() {
    this.initializeReportingEngine();
    this.initializeFilters();
    this.initializeGroupBys();
    this.initializeControls();
    this.restoreQuery();
    this.initTableSorter();
  }

  disconnect() {
    // Clean up event handlers if needed
  }

  // Called from data-action
  addFilter(evt:InputEvent) {
    const target = evt.target as HTMLSelectElement;
    if (!this.filters.exists(target.value)) {
      this.filters.add_filter(target.value);
      const newFilter = target.value;
      target.selectedIndex = 0;
      setTimeout(() => {
        jQuery(`#operators\\[${newFilter}\\]`).focus();
      }, 300);
    }
  }

  removeFilter(evt:MouseEvent) {
    evt.preventDefault();
    const removeBox = evt.currentTarget as HTMLElement;
    const filterNameInput = removeBox.querySelector<HTMLInputElement>('input[name="fields[]"]')?.value.trim();
    const filterName = filterNameInput && filterNameInput.length > 0
      ? filterNameInput
      : removeBox.closest('li')?.getAttribute('data-filter-name');

    if (filterName) {
      this.filters.remove_filter(filterName);
    }
  }

  filterKeydown(evt:KeyboardEvent) {
    if (evt.key === 'Enter' || evt.key === ' ') {
      evt.preventDefault();
      evt.stopPropagation();

      const removeBox = (evt.currentTarget as HTMLElement).closest<HTMLElement>('[id^="rm_box_"]');
      const filter = removeBox?.closest('li');
      if (!filter) {
        return;
      }

      const filterName = filter.dataset.filterName;
      const prevVisibleFilter = jQuery(filter)
        .prevAll(':visible')
        .last()
        .find('.advanced-filters--select');

      if (prevVisibleFilter.length > 0) {
        prevVisibleFilter.focus();
      } else {
        jQuery('#filters > legend a')[0]?.focus();
      }

      if (filterName) {
        this.filters.remove_filter(filterName);
      }
    }
  }

  onOperatorInput(evt:InputEvent) {
    const target = evt.target as HTMLSelectElement;
    const filterName = target.dataset.filterName;
    if (filterName) {
      this.filters.operator_changed(filterName, jQuery(target));
      const argVal = jQuery(`#${filterName}_arg_1_val`)[0];
      if (argVal) {
        this.fireEvent(argVal, 'change');
      }
    }
  }

  toggleMultiSelect(evt:MouseEvent) {
    const target = evt.currentTarget as HTMLElement;
    const filterName = target.dataset.filterName;

    if (filterName) {
      this.filters.toggle_multi_select(jQuery(`#${filterName}_arg_1_val`));
    }
  }

  selectValueChanged(evt:InputEvent) {
    const select = evt.target as HTMLSelectElement;
    const filterName = select.closest('li')?.getAttribute('data-filter-name');

    if (filterName) {
      this.filters.value_changed(filterName);
    }
  }

  addGroupBy(evt:InputEvent) {
    const target = evt.target as HTMLSelectElement;
    if (!this.groupBys.exists(target.value)) {
      this.groupBys.add_group_by_from_select(target);
    }
  }

  /**
   * Ported from legacy asset pipeline reporting
   */
  private initTableSorter() {
    // This prevents the tablesorter plugin to check for metadata which is done
    // using eval which conflicts with our csp.
    // Works because of a check in tablesorter:
    jQuery.metadata = undefined;

    // Override the default texts to enable translations
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    jQuery.tablesorter.language = {
      sortAsc: I18n.t('js.sort.sorted_asc'),
      sortDesc: I18n.t('js.sort.sorted_dsc'),
      sortNone: I18n.t('js.sort.sorted_no'),
      sortDisabled: I18n.t('js.sort.sorting_disabled'),
      nextAsc: I18n.t('js.sort.activate_asc'),
      nextDesc: I18n.t('js.sort.activate_dsc'),
      nextNone: I18n.t('js.sort.activate_no'),
    };

    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    jQuery('#sortable-table')
      .not('.tablesorter')
      .tablesorter({
        sortList: [[0, 0]],
        widgets: ['saveSort'],
        widgetOptions: {
          storage_storageType: 's',
        },
        textExtraction(node:HTMLElement) {
          return node.getAttribute('raw-data');
        },
      });
  }

  private flash(string:string, type = 'error') {
    const options = type === 'error'
      ? { id: 'errorExplanation', class: 'errorExplanation' }
      : { id: `flash_${type}`, class: `flash ${type}` };

    jQuery(`#${options.id}`).remove();

    const flashElement = jQuery('<div></div>')
      .attr('id', options.id)
      .attr('class', options.class)
      .attr('tabindex', '0')
      .attr('role', 'alert')
      .html(string);

    jQuery('#content').prepend(flashElement);
    jQuery(`#${options.id}`).focus();
  }

  private clearFlash() {
    jQuery('div[id^=flash]').remove();
  }

  private fireEvent(element:HTMLElement, event:string) {
    const evt = new Event(event, { bubbles: true, cancelable: true });
    return !element.dispatchEvent(evt);
  }

  private initializeReportingEngine() {
    // The main reporting methods are now instance methods on this controller
  }

  private initializeFilters() {
    this.filters = {
      loadAvailableValuesForFilter: (filterName:string, callbackFunc:() => void) => {
        const select = jQuery(`.filter-value[data-filter-name="${filterName}"]`).first();
        const radioOptions = jQuery(`.${filterName}_radio_option input`);

        if (radioOptions && radioOptions.length !== 0) {
          (radioOptions.first()[0] as HTMLInputElement).checked = true;
          callbackFunc();
        }

        if (!select.length) {
          return;
        }

        if (select.attr('data-loading') === 'ajax' && select.children().length === 0) {
          this.loadAvailableValuesForFilterFromRemote(select, filterName, callbackFunc);
          this.multiSelect(select, false);
        } else {
          callbackFunc();
        }
      },

      add_filter: (filterName:string) => {
        this.selectOptionEnabled(jQuery('#add_filter_select'), filterName, false);
        this.showFilter(filterName, { slowly: true });
      },

      clear: () => {
        this.visibleFilters().forEach((filter) => {
          this.filters.remove_filter(filter);
        });
      },

      exists: (filter:string) => {
        return this.visibleFilters().includes(filter);
      },

      operator_changed: (field:string, select:JQuery) => {
        this.operatorChanged(field, select);
      },

      remove_filter: (field:string, hideOnly = false) => {
        this.showFilter(field, { show_filter: false, hide_only: hideOnly });
        this.selectOptionEnabled(jQuery('#add_filter_select'), field, true);
      },

      select_option_enabled: (box:JQuery, value:string, state:boolean) => {
        this.selectOptionEnabled(box, value, state);
      },

      select_values: (selectBox:JQuery, valuesToSelect:string[]) => {
        this.selectValues(selectBox, valuesToSelect);
      },

      toggle_multi_select: (select:JQuery) => {
        this.multiSelect(select, !select.attr('multiple'));
      },

      value_changed: (field:string) => {
        this.valueChanged(field);
      },
    };

    jQuery('.advanced-filters--filter-value .filter-value').each((index, element) => {
      const select = jQuery(element);
      const selectValue = select.val();

      if (element.tagName.toLowerCase() !== 'opce-project-autocompleter') {
        const isMultiple = selectValue && Array.isArray(selectValue) && selectValue.length > 1;
        select.attr('multiple', isMultiple ? 'multiple' : null);
      }
    });
  }

  private loadAvailableValuesForFilterFromRemote(select:JQuery, filterName:string, callbackFunc:() => void) {
    const url = select.attr('data-remote-url')!;
    const jsonPostSelectValues = select.attr('data-initially-selected');
    let postSelectValues:string[]|undefined;

    if (jsonPostSelectValues !== null && jsonPostSelectValues !== undefined) {
      postSelectValues = JSON.parse(jsonPostSelectValues.replace(/'/g, '"')) as string[];
    }

    window.global_prefix ??= '';

    jQuery(`select[data-filter-name='${filterName}']`).prop('disabled', true);

    void post(url, {
      body: {
        filter_name: filterName,
        values: jsonPostSelectValues,
      },
      responseKind: 'html',
    })
    .then((response) => response.html)
    .then((html) => {
      const tagName = select.prop('tagName') as string | undefined;

      select.html(html);
      jQuery(`select[data-filter-name='${filterName}']`).prop('disabled', false);

      if (tagName?.toLowerCase() === 'select') {
        if (!postSelectValues || postSelectValues.length === 0) {
          (select[0] as HTMLSelectElement).selectedIndex = 0;
        } else {
          this.selectValues(select, postSelectValues);
        }
      }

      callbackFunc();
    });
  }

  private multiSelect(select:JQuery, multi:boolean) {
    select.attr('multiple', multi ? 'multiple' : null);
    if (multi) {
      select.attr('size', 4);
      if (select.find('option')[0]) {
        select.find('option').first().removeAttr('selected');
      }
    } else {
      select.attr('size', 1);
    }
  }

  private selectValues(selectBox:JQuery, valuesToSelect:string[]) {
    this.multiSelect(selectBox, valuesToSelect.length > 1);
    selectBox.val(valuesToSelect);
  }

  private showFilter(field:string, options:ShowFilterOptions = {}) {
    const defaultOptions = {
      callback_func: () => undefined,
      slowly: false,
      show_filter: true,
      hide_only: false,
    };

    options = { ...defaultOptions, ...options };

    const fieldEl = jQuery(`#filter_${field}`);
    if (fieldEl.length) {
      options.insert_after ??= this.lastVisibleFilter();

      if (options.insert_after && options.show_filter) {
        if (fieldEl.attr('id') !== options.insert_after.id) {
          fieldEl.detach();
          jQuery(`#${options.insert_after.id}`).after(fieldEl);
        }
      }

      if (options.show_filter) {
        // eslint-disable-next-line @typescript-eslint/no-unused-expressions
        options.slowly ? fieldEl.fadeIn('slow') : fieldEl.show();
        this.filters.loadAvailableValuesForFilter(field, options.callback_func ?? (() => undefined));
        jQuery(`#rm_${field}`).val(field);
        this.valueChanged(field);
      } else {
        // eslint-disable-next-line @typescript-eslint/no-unused-expressions
        options.slowly ? fieldEl.fadeOut('slow') : fieldEl.hide();

        if (!options.hide_only) {
          fieldEl.removeAttr('data-selected');
        }
        jQuery(`#rm_${field}`).val('');
      }

      this.operatorChanged(field, jQuery(`#operators\\[${field}\\]`));
      this.displayCategory(jQuery(`#${fieldEl.attr('data-label')}`));
    }
  }

  private lastVisibleFilter() {
    return jQuery('.advanced-filters--filter:visible').last()[0];
  }

  private displayCategory(label:JQuery) {
    if (label.length) {
      jQuery('.advanced-filters--filter').each(() => {
        const filter = jQuery(this);
        if (filter.is(':visible') && filter.attr('data-label') === label.attr('id')) {
          label.show();
          return;
        }
        label.hide();
      });
    }
  }

  private operatorChanged(field:string, select:JQuery) {
    if (!select?.length) {
      return;
    }
    const optionTag = select.find(`option[value="${select.val() as string}"]`);
    const arity = parseInt(optionTag.attr('data-arity')!, 10);
    const forcedType = optionTag.attr('data-forced')!;
    this.changeArgumentVisibility(field, arity, forcedType);
  }

  private valueChanged(field:string) {
    const val = jQuery(`#${field}_arg_1_val`);
    const filter = jQuery(`#filter_${field}`);
    if (!val.length) {
      return;
    }
    if ((val[0] as HTMLInputElement).value === '<<inactive>>') {
      filter.addClass('inactive-filter');
    } else {
      filter.removeClass('inactive-filter');
    }
  }

  private knownForcedTypes = ['integers'];

  private changeArgumentVisibility(fieldName:string, argNr:number, forcedType:string) {
    const fields:[string, boolean][] = [
      [`#${fieldName}_arg_1`, [1, 2, -1].includes(argNr)],
      [`#${fieldName}_arg_2`, argNr === 2],
    ];


    for (const [fieldSelector, active] of fields) {
      this.setActiveState(fieldSelector, active && !forcedType);
      this.knownForcedTypes.forEach((knownForcedType) => {
        this.setActiveState(`${fieldSelector}_${knownForcedType}`, active && forcedType === knownForcedType);
      });
    }
  }

  private setActiveState(selector:string, active:boolean) {
    const input = document.querySelector<HTMLElement>(selector);

    if (!input) {
      return;
    }

    input.hidden = !active;
    Array.from(input.children).forEach((child) => {
      (child as HTMLElement).hidden = !active;
      (child as HTMLInputElement).disabled = !active;
    });
  }

  private selectOptionEnabled(box:JQuery, value:string, state:boolean) {
    box.find(`[value='${value}']`).attr('disabled', state ? null : 'disabled');
  }

  private visibleFilters() {
    return jQuery('#filter_table .advanced-filters--filter:visible')
      .map((i, el) => el.dataset.filterName)
      .get();
  }

  private initializeGroupBys() {
    this.groupBys = {
      group_by_container_ids: ():string[] => {
        const ids = ['group-by--columns', 'group-by--rows'];
        return ids.filter((id) => jQuery(`#${id}`).length > 0);
      },

      initialize_drag_and_drop_areas: () => {
        this.recreateSortables();
      },

      add_group_by: (field:string, caption:string, container:JQuery) => {
        const groupBy = this.createGroupBy(field, caption);
        const addedContainer = container.find('.group-by--selected-elements');
        addedContainer.append(groupBy);
        this.addingGroupByEnabled(field, false);
      },

      add_group_by_from_select: (select:HTMLSelectElement) => {
        const jselect = jQuery(select);
        const field = jselect.val() as string;
        const container = jselect.closest('.group-by--container');
        const selectedOption = jselect.find(`[value='${field}']`).first();
        const caption = selectedOption.attr('data-label') ?? '';

        this.groupBys.add_group_by(field, caption, container);
        jselect.find('[value=\'\']').first().attr('selected', 'selected');
      },

      clear: () => {
        this.visibleGroupBys().forEach((groupBy:string) => {
          jQuery(`#${groupBy} .group-by--selected-element`).each((index, element) => {
            this.removeGroupBy(jQuery(element));
          });
        });
      },

      create_group_by: (field:string, caption:string) => {
        return this.createGroupBy(field, caption);
      },

      exists: (groupByName:string) => {
        return this.visibleGroupBys().some((grp) =>
          jQuery(`#${grp}`).attr('data-group-by') === groupByName);
      },
    };

    // Initialize drag and drop
    this.groupBys.initialize_drag_and_drop_areas();
  }

  private recreateSortables() {
    const containers = Array.from(document.querySelectorAll('.group-by--selected-elements'));
    dragula(containers, {
      mirrorContainer: document.getElementById('group-by--area')!,
    });
  }

  private createLabel(groupBy:JQuery, text:string) {
    const groupById = groupBy.attr('id') ?? '';
    return jQuery('<label></label>')
      .attr('class', 'in_row group-by--label')
      .attr('for', groupById)
      .attr('id', `${groupById}_label`)
      .attr('title', text)
      .text(text);
  }

  private createRemoveButton(groupBy:JQuery) {
    const removeLink = jQuery('<a></a>')
      .attr('class', 'group-by--remove in_row')
      .attr('id', `${groupBy.attr('id')}_remove`)
      .attr('href', '');

    const removeIcon = jQuery('<span><span>')
      .attr('class', 'icon-context icon-close icon4');

    const title = `${window.I18n.t('js.reporting_engine.label_remove')} ${groupBy.find('label').html()}`;
    removeLink.attr('title', title);
    removeIcon.attr('alt', title);

    removeLink.on('click', (e) => {
      e.preventDefault();
      this.removeElementEventAction(groupBy, removeLink);
    });

    removeLink.on('keypress', (e) => {
      if (e.key === ' ') {
        e.preventDefault();
        this.removeElementEventAction(groupBy, removeLink);
      }
    });

    removeLink.append(removeIcon);
    return removeLink;
  }

  private removeElementEventAction(groupBy:JQuery, button:JQuery) {
    const linkNode = groupBy.next('span').find('a');
    const selectNode = groupBy.next('select');

    if (linkNode.length) {
      linkNode.focus();
    } else if (selectNode.length) {
      selectNode.focus();
    }

    this.removeGroupBy(button.closest('.group-by--selected-element'));
  }

  private createGroupBy(field:string, caption:string) {
    const groupBy = jQuery('<span></span>')
      .attr('class', 'group-by--selected-element')
      .attr('data-group-by', field);

    ensureId(groupBy[0]); // give it a unique id

    const label = this.createLabel(groupBy, caption);
    groupBy.append(label);

    const removeButton = this.createRemoveButton(groupBy);
    groupBy.append(removeButton);

    return groupBy;
  }

  private addingGroupByEnabled(field:string, state:boolean) {
    ['#group-by--add-columns', '#group-by--add-rows'].forEach((containerId) => {
      this.filters.select_option_enabled(jQuery(containerId), field, state);
    });
  }

  private removeGroupBy(groupBy:JQuery) {
    this.addingGroupByEnabled(groupBy.attr('data-group-by')!, true);
    groupBy.remove();
  }

  private visibleGroupBys():string[] {
    return this.groupBys.group_by_container_ids().filter((container:string) =>
      jQuery(`#${container}`).find('[data-group-by]').length > 0);
  }

  private initializeControls() {
    this.controls = {
      attach_settings_callback: (element:JQuery, callback:(response:string) => void) => {
        this.attachSettingsCallback(element, callback);
      },

      clear_query: (e:Event) => {
        e.preventDefault();
        this.filters.clear();
        this.groupBys.clear();
      },

      observe_click: (elementId:string, callback:(e:Event) => void) => {
        const target = document.getElementById(elementId)!;
        target?.addEventListener('click', callback);
      },

      update_result_table: (response:string) => {
        jQuery('#result-table').html(response);
        this.initTableSorter();
      },

      toggle_delete_form: (e:Event) => {
        e.preventDefault();
        const offset = jQuery('#query-icon-delete').offset()?.left ?? 0;
        jQuery('#delete_form').css('left', `${offset}px`).toggle();
      },

      toggle_save_as_form: (e:Event) => {
        e.preventDefault();
        const offset = jQuery('#query-icon-save-as').offset()?.left ?? 0;
        jQuery('#save_as_form').css('left', `${offset}px`).toggle();
      },
    };

    // Bind control events
    if (jQuery('#query_saved_name').length) {
      if (jQuery('#query_saved_name').attr('data-is_new')) {
        if (jQuery('#query-icon-delete').length) {
          this.controls.observe_click('query-icon-delete', this.controls.toggle_delete_form);
          this.controls.observe_click('query-icon-delete-cancel', this.controls.toggle_delete_form);
          jQuery('#delete_form').hide();
        }

        if (jQuery('#query-breadcrumb-save').length) {
          this.controls.attach_settings_callback(jQuery('#query-breadcrumb-save'), this.controls.update_result_table);
        }
      }
    }

    this.controls.observe_click('query-icon-save-as', this.controls.toggle_save_as_form);
    this.controls.observe_click('query-icon-save-as-cancel', this.controls.toggle_save_as_form);

    jQuery('#save_as_form').hide();

    this.controls.attach_settings_callback(jQuery('#query-icon-save-button'), (newLocation:string) => {
      document.location.href = newLocation;
    });

    this.controls.attach_settings_callback(jQuery('#query-icon-apply-button'), this.controls.update_result_table);

    this.controls.observe_click('query-link-clear', this.controls.clear_query);
  }

  private attachSettingsCallback(element:JQuery, callback:(response:string) => void) {
    if (!element?.length) {
      return;
    }

    const failureCallback = (error:unknown) => {
      jQuery('#result-table').html('');
      this.defaultFailureCallback(error);
    };

    element[0].addEventListener('click', (e:Event) => {
      e.preventDefault();
      const target = jQuery(e.target as HTMLElement).closest('[data-target]').attr('data-target');
      this.sendSettingsData(target ?? '', callback, failureCallback);
    });
  }

  private sendSettingsData(targetUrl:string, callback:(_result:string) => void, failureCallback?:(_error:unknown) => void) {
    const errorCallback = failureCallback ?? this.defaultFailureCallback;
    this.clearFlash();

    void post(targetUrl, { body: this.serializeSettingsForm() })
      .then((response) => {
        if (response.unprocessableEntity) {
          return response.text.then((errorText) => { throw new ValidationError(errorText); });
        }
        if (!response.ok) {
          throw new FetchRequestError(response.statusCode);
        }

        return response.text;
      })
      .then(callback)
      .catch(errorCallback);
  }

  private serializeSettingsForm() {
    const queryForm = document.querySelector<HTMLFormElement>('#query_form')!;
    const formData = new FormData(queryForm);
    this.syncActiveFilters(formData);

    ['rows', 'columns'].forEach((type) => {
      Array.from(document.querySelectorAll<HTMLElement>(`#group-by--${type} .group-by--selected-element`))
        .map((el) => el.dataset.groupBy)
        .filter((value) => value !== undefined)
        .forEach((value) => {
          formData.append(`groups[${type}][]`, value);
        });
    });

    return formData;
  }

  private syncActiveFilters(formData:FormData) {
    formData.delete('fields[]');

    this.visibleFilters().forEach((field) => {
      const operator = this.filterOperator(field);
      const hasValues = this.syncFilterValues(formData, field);

      if (operator && operator.arity > 0 && !hasValues) {
        formData.delete(`operators[${field}]`);
        return;
      }

      formData.append('fields[]', field);
      this.syncFilterOperator(formData, field, operator?.value);
    });
  }

  private syncFilterOperator(formData:FormData, field:string, operatorValue?:string) {
    const name = `operators[${field}]`;
    const selectedOperator = operatorValue ?? this.filterOperator(field)?.value;

    if (!selectedOperator) {
      return;
    }

    formData.delete(name);
    formData.append(name, selectedOperator);
  }

  private syncFilterValues(formData:FormData, field:string) {
    const arrayName = `values[${field}][]`;
    const scalarName = `values[${field}]`;
    const filter = document.querySelector<HTMLElement>(`#filter_${field}`);

    formData.delete(arrayName);
    formData.delete(scalarName);
    if (!filter) {
      return false;
    }

    const fields = Array.from(filter.querySelectorAll<HTMLInputElement|HTMLSelectElement|HTMLTextAreaElement>('input, select, textarea'))
      .filter((element) => element.name === arrayName || element.name === scalarName)
      .filter((element) => !element.disabled);

    const nonEmptyFields = fields.filter((element) => element.value !== '');
    if (nonEmptyFields.length === 0) {
      return this.serializeFilterComponentValue(formData, filter, arrayName);
    }

    let serializedValueCount = 0;
    nonEmptyFields.forEach((element) => {
      if (element instanceof HTMLSelectElement) {
        const selectedOptions = Array.from(element.selectedOptions);

        if (selectedOptions.length === 0) {
          formData.append(element.name, element.value);
          serializedValueCount += 1;
          return;
        }

        selectedOptions.forEach((option) => {
          formData.append(element.name, option.value);
          serializedValueCount += 1;
        });

        return;
      }

      if ((element instanceof HTMLInputElement) && ['checkbox', 'radio'].includes(element.type) && !element.checked) {
        return;
      }

      formData.append(element.name, element.value);
      serializedValueCount += 1;
    });

    return serializedValueCount > 0;
  }

  private serializeFilterComponentValue(formData:FormData, filter:HTMLElement, name:string) {
    // Reporting filters embed Angular custom elements that may not materialize
    // matching named inputs until the user interacts with them.
    const datePicker = filter.querySelector<HTMLElement>('[data-name][data-value]');
    const normalizedName = this.normalizeQuotedDatasetValue(datePicker?.dataset.name);
    const dateValue = this.normalizeQuotedDatasetValue(datePicker?.dataset.value);

    if (normalizedName === name && dateValue) {
      formData.append(name, dateValue);
      return true;
    }

    const autocompleter = filter.querySelector<HTMLElement>('[data-input-name][data-model]');
    const inputName = this.normalizeQuotedDatasetValue(autocompleter?.dataset.inputName);

    if (inputName !== name.replace(/\[\]$/, '')) {
      return false;
    }

    const parsedModel = this.parseQuotedJson(autocompleter?.dataset.model);
    if (!Array.isArray(parsedModel)) {
      return false;
    }

    let serializedValueCount = 0;
    parsedModel
      .map((value) => this.autocompleterValueId(value))
      .filter((value):value is string => typeof value === 'string' && value.length > 0)
      .forEach((value) => {
        formData.append(name, value);
        serializedValueCount += 1;
      });

    return serializedValueCount > 0;
  }

  private filterOperator(field:string) {
    const operatorName = `operators[${field}]`;
    const operatorSelect = document.querySelector<HTMLSelectElement>(`[name="${operatorName}"]`);
    const selectedValue = operatorSelect?.value;

    if (!operatorSelect || !selectedValue) {
      return undefined;
    }

    const selectedOption = operatorSelect.selectedOptions[0];
    const arity = parseInt(selectedOption?.dataset.arity ?? '0', 10);

    return {
      value: selectedValue,
      arity,
    };
  }

  private autocompleterValueId(value:unknown) {
    if (!value || typeof value !== 'object' || !('id' in value)) {
      return undefined;
    }

    const { id } = value;
    if (typeof id === 'string') {
      return id;
    }

    if (typeof id === 'number') {
      return String(id);
    }

    return undefined;
  }

  private normalizeQuotedDatasetValue(value?:string) {
    if (!value) {
      return value;
    }

    // AngularHelper serializes string inputs with `.to_json`, so string
    // dataset values arrive wrapped in literal double quotes.
    return value.replace(/^"+|"+$/g, '');
  }

  private parseQuotedJson(value?:string):unknown {
    if (!value) {
      return undefined;
    }

    try {
      return JSON.parse(value);
    } catch {
      return undefined;
    }
  }

  private defaultFailureCallback = (error:unknown) => {
    if (error instanceof ValidationError) {
      this.flash(error.message);
    } else {
      this.flash(window.I18n.t('js.reporting_engine.label_response_error'));
    }
  };

  private restoreQuery() {
    this.restoreQueryModule = {
      restore_group_bys: () => {
        this.groupBys.group_by_container_ids().forEach((id:string) => {
          const container = jQuery(`#${id}`);
          const selectedContainers = container.attr('data-initially-selected');

          if (selectedContainers) {
            const selectedGroups = JSON.parse(selectedContainers.replace(/'/g, '"')) as (string[])[];
            selectedGroups.forEach((groupAndLabel:[string, string]) => {
              const [group, label] = groupAndLabel;
              this.groupBys.add_group_by(group, label, container);
            });
          }
        });
      },

      restore_filters: () => {
        jQuery('.advanced-filters--select.filter-value').each((index, element) => {
          const jselect = jQuery(element);
          const tr = jselect.closest('li');

          if (tr.is(':visible')) {
            const filter = tr.attr('data-filter-name');
            const dependent = jselect.attr('data-dependent');

            if (filter && dependent) {
              this.filters.remove_filter(filter, false);
            }
          }
        });

        jQuery('li.advanced-filters--filter[data-selected=true]').each((index, element) => {
          const filter = jQuery(element);
          const select = filter.find('.advanced-filters--filter-value select');
          if (select.length && select.attr('data-dependent')) return;
          const filterName = filter.attr('data-filter-name');
          if (filterName) {
            this.filters.add_filter(filterName);
          }
        });
      },
    };

    // Execute restore operations
    this.restoreQueryModule.restore_group_bys();
    this.restoreQueryModule.restore_filters();
  }
}
