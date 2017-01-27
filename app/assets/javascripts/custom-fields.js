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
(function(window, $) {
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
        multiSelect           = $('#custom_field_multi_select'),
        possibleValues        = $('#custom_field_possible_values_attributes'),
        defaultValueFields    = $('#custom_field_default_value_attributes'),
        spanDefaultText       = $('#default_value_text'),
        spanDefaultBool       = $('#default_value_bool');

    var deactivate = function(element) {
      element.hide().find('input, textarea').not('.destroy_flag,.-cf-ignore-disabled').attr('disabled', true);
    },
    activate = function(element) {
      element.show().find('input, textarea').not('.destroy_flag,.-cf-ignore-disabled').removeAttr('disabled');
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
      $.each([spanDefaultBool, spanDefaultText, multiSelect], function(idx, element) {
        deactivate(element);
      });
      show(defaultValueFields);
      activate(spanDefaultText);

      switch (format.val()) {
        case 'list':
          deactivate(defaultValueFields);
          hide(lengthField, regexpField, defaultValueFields);
          show(searchable, multiSelect);
          activate(multiSelect);
          activate(possibleValues);
          break;
        case 'bool':
          activate(spanDefaultBool);
          deactivate(spanDefaultText);
          deactivate(possibleValues);
          hide(lengthField, regexpField, searchable);
          unsearchable();
          break;
        case 'date':
          deactivate(defaultValueFields);
          deactivate(possibleValues);
          hide(lengthField, regexpField, defaultValueFields);
          unsearchable();
          break;
        case 'float':
        case 'int':
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

  var moveUpRow = function() {
    var row = $(this).closest("tr");
    var above = row.prev("tr");

    above.before(row);

    return false;
  };

  var moveDownRow = function() {
    var row = $(this).closest("tr");
    var after = row.next("tr");

    after.after(row);

    return false;
  };

  var moveRowToTheTop = function() {
    var row = $(this).closest("tr");
    var first = jQuery(row.siblings()[0]);

    first.before(row);

    return false;
  };

  var moveRowToTheBottom = function() {
    var row = $(this).closest("tr");
    var last = jQuery(row.siblings().last()[0]);

    last.after(row);

    return false;
  };

  var removeOption = function() {
    var self = $(this);
    if (self.attr("href") === "#" || self.attr("href").endsWith("/0")) {
      var row = self.closest("tr");

      if (row.siblings().length > 1) {
        row.remove();
      }

      return false; // just remove new element
    } else {
      return true; // send off deletion
    }
  };

  var rowDummyIdCounter = 500;

  var duplicateRow = function() {
    var row = $("#custom-options-table tr.custom-option-row:last");
    var dup = row.clone();

    var value = dup.find(".custom-option-value");

    rowDummyIdCounter++;

    value.attr("name", "custom_field[custom_options][new-" + rowDummyIdCounter + "][value]");
    value.val("");

    var defaultValue = dup.find(".custom-option-default-value");

    defaultValue.attr("name", "custom_field[custom_options][new-" + rowDummyIdCounter + "][default_value]");
    defaultValue.prop("checked", false);

    dup.find(".move-up-custom-option").click(moveUpRow);
    dup.find(".sort-up-custom-option").click(moveRowToTheTop);
    dup.find(".sort-down-custom-option").click(moveRowToTheBottom);
    dup.find(".move-down-custom-option").click(moveDownRow);
    dup.find(".custom-option-default-value").change(uncheckOtherDefaults);

    dup
      .find(".delete-custom-option")
      .attr("href", "#")
      .click(removeOption);

    dup.attr("id", "custom-option-row-" + rowDummyIdCounter);

    row.after(dup);

    return false;
  };

  var uncheckOtherDefaults = function() {
    var cb = $(this);

    if (cb.prop("checked")) {
      var multi = $('#custom_field_multi_value');

      if (!multi.prop("checked")) {
        $(".custom-option-default-value").each(function(i, other) {
          $(other).prop("checked", false);
        });

        cb.prop("checked", true);
      }
    }
  };

  var checkOnlyOne = function() {
    var cb = $(this);

    if (!cb.prop("checked")) {
      $(".custom-option-default-value:checked").slice(1).each(function(i, other) {
        $(other).prop("checked", false);
      });
    }
  };

  $(document).ready(function() {
    $("#add-custom-option").click(duplicateRow);
    $(".delete-custom-option").click(removeOption);

    $(".move-up-custom-option").click(moveUpRow);
    $(".move-down-custom-option").click(moveDownRow);

    $(".sort-up-custom-option").click(moveRowToTheTop);
    $(".sort-down-custom-option").click(moveRowToTheBottom);

    $(".custom-option-default-value").change(uncheckOtherDefaults);
    $('#custom_field_multi_value').change(checkOnlyOne);
  });

  window.CustomFields = {
    allowDrop: function(event) {
      if ($(event.target).hasClass("custom-option-value-row")) {
        event.preventDefault();
      }
    },
    drag: function(event) {
      event.dataTransfer.setData("text", event.target.id);
    },
    drop: function(event) {
      var id = event.dataTransfer.getData("text");
      var from = $(document.getElementById(id));
      var to = $(event.target).closest("tr.custom-option-row");

      if (from && to) {
        var fromIndex = from.parent().children().index(from);
        var toIndex = from.parent().children().index(to);

        if (fromIndex < toIndex) {
          to.after(from);
        } else {
          to.before(from);
        }
      }
    }
  };
}(window, jQuery));
