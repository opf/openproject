//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
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

  function parseFilters() { 
    let $advancedFilters = $(".advanced-filters--filter:not(.hidden)", $filterForm);
    let filters = [];

    $advancedFilters.each(function(_i, filter) {
      let $filter = $(filter);
      let filterName = $filter.attr('filter-name');
      let parsedOperator = $('select[name="operator"]', $filter).val();
      let parsedValue = parseFilterValue($filter, parsedOperator);

      if (parsedValue) {
        let filter = {}
        filter[filterName] = { 'operator': parsedOperator, 'values': parsedValue };

        filters.push(filter);
      }
    });

    return filters;
  }

  function parseFilterValue($filter, operator) {
    let filterType = $filter.attr('filter-type');
    let $valueBlock = $('.advanced-filters--filter-value', $filter);

    if (operatorsWithoutValues.includes(operator)) {
      return [];
    } else if (selectFilterTypes.includes(filterType)) {
      // Operator expects presence of value(s)
      return parseSelectFilterValue($valueBlock);
    } else if (['datetime_past', 'date'].includes(filterType)) {
      return parseDateFilterValue($valueBlock);
    } else {
      // not a select box nor datetime_past
      let value = $('input[name="value"]', $valueBlock).val();
      if (value.length > 0) {
        return [value];
      }
    }
  }

  function parseSelectFilterValue($valueBlock) {
    let selector;

    if ($valueBlock.hasClass('multi-value')) {
      selector = '.multi-select select[name="value[]"]';
    } else {
      selector = '.single-select select[name="value"]';
    }

    let values = $(selector, $valueBlock).val();
    values = _.flatten([values]);

    if (values.length > 0) {
      return values;
    }
  }

  function parseDateFilterValue($valueBlock) {
    let value;

    if ($valueBlock.hasClass('days')) {
      value = _.without([$('.days input[name="value"]', $valueBlock).val()], '');
    } else if ($valueBlock.hasClass('on-date')) {
      value = _.without([$('.on-date input[name="value"]', $valueBlock).val()], '');
    } else if ($valueBlock.hasClass('between-dates')) {
      let fromValue = $('.between-dates input[name="from_value"]',
                        $valueBlock).val();
      let toValue   = $('.between-dates input[name="to_value"]',
                        $valueBlock).val();

      value = [fromValue, toValue];
    }

    if (value.length > 0) {
      return value;
    }
  }

  function sendForm() {
    $('#ajax-indicator').show();
    let filters = parseFilters();
    let orderParam = getUrlParameter('sort');


    let query = '?filters=' + encodeURIComponent(JSON.stringify(filters));
    if (orderParam && orderParam.length > 0) {
      query = query + '&sortBy=' + encodeURIComponent(orderParam);
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
    $('#add_filter_select option:selected', $filterForm).prop('disabled','disabled');
    jQuery('#add_filter_select option:first-of-type').prop('selected','selected');
    setSpacerVisibility();
    return false;
  }

  function removeFilter(e) {
    e.preventDefault();
    let $filter = $(this).parents('.advanced-filters--filter');
    let filterName = $filter.attr('filter-name');

    $filter.addClass('hidden');
    $('#add_filter_select option[value="' + filterName + '"]', $filterForm).removeAttr('disabled');
    setSpacerVisibility();
  }

  function setSpacerVisibility() {
    let remaining = $(".advanced-filters--filter:not(.hidden)").length;
    $('.advanced-filters--spacer').toggle(remaining > 0);
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
