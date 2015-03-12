//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++
(function($) {
  /*
   * @see /app/views/custom_fields/_form.html.erb
   */
  $(function() {
    var customFieldForm = $('#custom_field_form');

    if (customFieldForm.length === 0) {
      return;
    }

    // collect the nodes involved
    var format                = $('#custom_field_field_format'),
        lengthField           = $('#custom_field_length'),
        regexpField           = $('#custom_field_regexp'),
        possibleValues        = $('#custom_field_possible_values_attributes'),
        defaultValueFields    = $('#custom_field_default_value_attributes'),
        spanDefaultTextMulti  = $('#default_value_text_multi'),
        spanDefaultTextSingle = $('#default_value_text_single'),
        spanDefaultBool       = $('#default_value_bool');

    var deactivate = function(element) {
      element.hide().find('input, textarea').not('.destroy_flag').attr('disabled', true);
    },
    activate = function(element) {
      element.show().find('input, textarea').not('.destroy_flag').removeAttr('disabled');
    },
    toggleVisibility = function(method, args) {
      var fields = Array.prototype.slice.call(args);
      $.each(fields, function(idx, field) {
        field.closest('.form--field, .form--grouping')[method]();
      });
    },
    hide = function() { toggleVisibility('hide', arguments); },
    show = function() { toggleVisibility('show', arguments); },
    toggleFormat = function() {
      var searchable   = $('#searchable_container'),
          unsearchable = function() { searchable.attr('checked', false).hide(); };

      // defaults (reset these fields before doing anything else)
      $.each([spanDefaultBool, spanDefaultTextSingle], function(idx, element) {
        deactivate(element);
      });
      show(defaultValueFields);
      activate(spanDefaultTextMulti);

      switch (format.val()) {
        case 'list':
          hide(lengthField, regexpField);
          show(searchable);
          activate(possibleValues);
          break;
        case 'bool':
          activate(spanDefaultBool);
          deactivate(spanDefaultTextMulti);
          deactivate(possibleValues);
          hide(lengthField, regexpField, searchable);
          unsearchable();
          break;
        case 'date':
          activate(spanDefaultTextSingle);
          deactivate(spanDefaultTextMulti);
          deactivate(possibleValues);
          hide(lengthField, regexpField);
          unsearchable();
          break;
        case 'float':
        case 'int':
          activate(spanDefaultTextSingle);
          deactivate(spanDefaultTextMulti);
          deactivate(possibleValues);
          show(lengthField, regexpField);
          unsearchable();
          break;
        case 'user':
        case 'version':
          deactivate(defaultValueFields);
          deactivate(possibleValues);
          hide(lengthField, regexpField, defaultValueFields);
          unsearchable();
          break;
        default:
          show(lengthField, regexpField, searchable);
          deactivate(possibleValues);
          break;
      }
    };

    // assign the switch format function to the select field
    format.on('change', toggleFormat).trigger('change');
  });

  $(function() {
    var localeSelectors = $('.locale_selector');

    localeSelectors.change(function () {
      var lang = $(this).val(),
          span = $(this).closest('.translation');
      span.attr('lang', lang);
    }).trigger('change');
  });
}(jQuery));
