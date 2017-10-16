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
    let $simpleFilters = $(".simple-filters--filter", $filterForm);
    let filters = [];
    $simpleFilters.each(function(_i, filter){
      let $filter = $(filter);
      let fieldName = $('label', $filter).attr('for');

      if (fieldName == 'name') {
        let value = $('input[name="name"]', $filter).val();
        if (value && value.length > 0) {
          filters.push({
            'name_and_identifier':{
              'operator': '~',
              'values': [$('input[name="name"]', $filter).val()]
            }
          });
        }
      } else if (fieldName == 'status') {
        let operator = '*';
        let value = '';
        if ($('select[name="status"]', $filter).val() != "all") {
          operator = '=';
          value = $('select[name="status"]', $filter).val();
        }
        filters.push({
          'status':{
            'operator': operator,
            'values': [value]
          }
        });
      }
    })
    let query = '?filters=' + JSON.stringify(filters);
    window.location = window.location.pathname + query;
    return false;
  }

  $filterForm.submit(sendForm)
  $button.click(toggleProjectFilterForm);
  $closeIcon.click(toggleProjectFilterForm);

});
