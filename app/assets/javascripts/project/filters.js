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

jQuery(function($) {
  let $filterForm = $('form.project-filters').first();
  let $button = $('#projects-filter-toggle-button');
  let operatorsWithoutValues = ['*', '!*', 't', 'w'];
  let selectFilterTypes = ['list', 'list_all', 'list_optional'];
  let $closeIcon = $('#projects-filter-close-button');

  function toggleProjectFilterForm() {
    if($button.hasClass('-active')) {
      $button.removeClass('-active');
      $filterForm.removeClass('-expanded');
    } else {
      $button.addClass('-active');
      $filterForm.addClass('-expanded');
    }
  }

  function sendForm() {
    $('#ajax-indicator').show();
    let $advancedFilters = $(".advanced-filters--filter:not(.hidden)", $filterForm);
    let filters = [];
    let orderParam = getUrlParameter('sort');

    $advancedFilters.each(function(_i, filter){
      let $filter = $(filter);
      let filterName = $filter.attr('filter-name');
      let filterType = $filter.attr('filter-type');
      let operator = $('select[name="operator"]', $filter).val();

      let filterParam = {};

      if (operatorsWithoutValues.includes(operator)) {
        // operator does not expect a value
        filterParam[filterName] = {
          'operator': operator,
          'values': []
        }
        filters.push(filterParam);
      } else {
        // Operator expects presence of value(s)
        let $valueBlock = $('.advanced-filters--filter-value', $filter);
        if (selectFilterTypes.includes(filterType)) {
          if ($valueBlock.hasClass('multi-value')) {
            // Expect values to be an Array.
            let values = $('.multi-select select[name="value[]"]', $valueBlock).val();
            if (values.length > 0) {
              filterParam[filterName] = {
                'operator': operator,
                'values': values
              }
              // only add filter if a value is present.
              filters.push(filterParam);
            }
          } else {
            // Expect value to be a single value.
            let value = $('.single-select select[name="value"]', $valueBlock).val();
            if (value.length > 0) {
              filterParam[filterName] = {
                'operator': operator,
                'values': [value]
              }
              // only add filter if a value is present.
              filters.push(filterParam);
            }
          }
        } else if (['datetime_past', 'date'].includes(filterType)) {
          if ($valueBlock.hasClass('days')) {
            let value = $('.days input[name="value"]', $valueBlock).val();
            if (value.length > 0) {
              filterParam[filterName] = {
                'operator': operator,
                'values': [value]
              }
              // only add filter if a value is present.
              filters.push(filterParam);
            }
          } else if ($valueBlock.hasClass('on-date')) {
            let value = $('.on-date input[name="value"]', $valueBlock).val();
            if (value.length > 0) {
              filterParam[filterName] = {
                'operator': operator,
                'values': [value]
              }
              // only add filter if a value is present.
              filters.push(filterParam);
            }
          } else if ($valueBlock.hasClass('between-dates')) {
            let fromValue = $('.between-dates input[name="from_value"]',
                              $valueBlock).val();
            let toValue =   $('.between-dates input[name="to_value"]',
                              $valueBlock).val();
            if (value.length > 0) {
              filterParam[filterName] = {
                'operator': operator,
                'values': [fromValue, toValue]
              }
              // only add filter if a value is present.
              filters.push(filterParam);
            }
          }
        } else {
          // not a select box nor datetime_past
          let value = $('input[name="value"]', $valueBlock).val();
          if (value.length > 0) {
            filterParam[filterName] = {
              'operator': operator,
              'values': [value]
            };
            // only add filter if a value is present.
            filters.push(filterParam);
          }
        }
      }
    });

    let query = '?filters=' + encodeURIComponent(JSON.stringify(filters));
    if (orderParam && orderParam.length > 0) {
      query = query + '&sort=' + encodeURIComponent(orderParam);
    }

    window.location = window.location.pathname + query;
    return false;
  }

  function toggleMultiselect(){
    let $self = $(this);
    let $valueSelector = $self.parents('.advanced-filters--filter-value');

    let $singleSelect = $('.single-select select', $valueSelector);
    let $multiSelect  = $('.multi-select select', $valueSelector);

    if ($valueSelector.hasClass('multi-value')) {
      let values = $multiSelect.val();
      let value = null;
      if (values && values.length > 1) {
        value = values[0];
      } else {
        value = values;
      }
      $singleSelect.val(value);
    } else {
      let value = $singleSelect.val();
      $multiSelect.val(value);
    }

    $valueSelector.toggleClass('multi-value');
    return false;
  }

  function addFilter(e) {
    e.preventDefault();
    $('[filter-name="' + $(this).val() + '"]').removeClass('hidden');
    // If the user removes the filter the same filter has to be selectable from fresh again:
    jQuery('#add_filter_select option').first().attr('selected','selected');
    return false;
  }

  function removeFilter(e) {
    let $filter = $(this).parents('.advanced-filters--filter');
    let filterName = $filter.attr('filter-name');

    $filter.addClass('hidden');
    $('#add_filter_select option[value="' + filterName + '"]', $filterForm).removeAttr('disabled');
    $('#add_filter_select option:selected', $filterForm).attr('disabled','disabled');
  }

  function setValueVisibility() {
    selectedOperator = $(this).val();
    $filter = $(this).parents('.advanced-filters--filter')
    $filterValue = $('.advanced-filters--filter-value', $filter);
    if (['*', '!*', 't', 'w'].includes(selectedOperator)) {
      $filterValue.addClass('hidden');
    } else {
      $filterValue.removeClass('hidden');
    }

    if (['>t-', '<t-', 't-', '<t+', '>t+', 't+'].includes(selectedOperator)) {
      $filterValue.addClass('days');
      $filterValue.removeClass('on-date');
      $filterValue.removeClass('between-dates');
    } else if (selectedOperator == '=d') {
      $filterValue.addClass('on-date');
      $filterValue.removeClass('days');
      $filterValue.removeClass('between-dates');
    } else if (selectedOperator == "<>d") {
      $filterValue.addClass('between-dates');
      $filterValue.removeClass('days');
      $filterValue.removeClass('on-date');
    }
  }

  // Register event listeners
  $('.advanced-filters--filter-value a.multi-select-toggle').click(toggleMultiselect);
  $button.click(toggleProjectFilterForm);
  $closeIcon.click(toggleProjectFilterForm);
  $filterForm.submit(sendForm);
  $('select[name="operator"]', $filterForm).on('change', setValueVisibility)
  $('#add_filter_select', $filterForm).on('change', addFilter);
  $('.filter_rem', $filterForm).on('click', removeFilter);


  // Helpers
  function getUrlParameter(sParam) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
      sURLVariables = sPageURL.split('&'),
      sParameterName,
      i;

    for (i = 0; i < sURLVariables.length; i++) {
      sParameterName = sURLVariables[i].split('=');

      if (sParameterName[0] === sParam) {
        return sParameterName[1] === undefined ? true : sParameterName[1];
      }
    }
  };
});
