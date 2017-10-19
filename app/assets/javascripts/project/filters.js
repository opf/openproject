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

  let operatorsWithoutValues = ['*', '!*'];
  let operatorsWithVaues = ['*', '!*'];

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
    let $advancedFilters = $(".advanced-filters--filter", $filterForm);
    let filters = [];
    $advancedFilters.each(function(_i, filter){
      let $filter = $(filter);
      let filterName = $filter.attr('filter-name');
      let operator = $('select[name="operator"]', $filter).val();
      let value = $('select[name="value"],input[name="value"]', $filter).val();
      let filterParam = {};
      if (operatorsWithoutValues.includes(operator)) {
        filterParam[filterName] = {
          'operator': operator,
          'values': []
        }
        filters.push(filterParam);
      } else {
        if (value && value.length > 0) {
          filterParam[filterName] = {
            'operator': operator,
            'values': [value]
          }
          filters.push(filterParam);
        }
      }
    })
    let query = '?filters=' + encodeURIComponent(JSON.stringify(filters));
    window.location = window.location.pathname + query;
    return false;
  }

  // Register event listeners
  $filterForm.submit(sendForm)
  $button.click(toggleProjectFilterForm);
  $closeIcon.click(toggleProjectFilterForm);
});
