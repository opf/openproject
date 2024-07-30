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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, */

Reporting.Filters = function($){
  var load_available_values_for_filter = function  (filter_name, callback_func) {
    var select, radio_options, post_select_values;
    select = $('.filter-value[data-filter-name="' + filter_name + '"]').first();
    // check if we might have a radio-box
    radio_options = $('.' + filter_name + '_radio_option input');
    if (radio_options && radio_options.length !== 0) {
      radio_options.first().checked = true;
      callback_func();
    }
    if (!select.length) {
      return;
    }
    if (select.attr('data-loading') === "ajax" && select.children().length === 0) {
      load_available_values_for_filter_from_remote(select, filter_name, callback_func);
      multi_select(select, false);
    } else {
      callback_func();
    }
  };

  var load_available_values_for_filter_from_remote = function(select, filter_name, callback_func) {
    var url = select.attr("data-remote-url"),
        json_post_select_values = select.attr('data-initially-selected'),
        post_select_values;

    if (json_post_select_values !== null && json_post_select_values !== undefined) {
      post_select_values = $.parseJSON(json_post_select_values.replace(/'/g, '"'));
    }

    if (window.global_prefix === undefined) {
      window.global_prefix = "";
    }

    $.ajax({
      url: url,
      method: 'POST',
      data: {
        filter_name: filter_name,
        values: json_post_select_values
      },
      beforeSend: function () {
        $("select[data-filter-name='" + filter_name + "']").attr('disable', true);
        $('#ajax-indicator').show();
      },
      complete: function (xhr) {
        var tagName = select.prop('tagName');

        select.html(xhr.responseText);
        $("select[data-filter-name='" + filter_name + "']").removeAttr('disable');
        if (tagName && tagName.toLowerCase() === "select") {
          if (!post_select_values || post_select_values.length === 0) {
            select.selectedIndex = 0;
          } else {
            select_values(select, post_select_values);
          }
        }
        callback_func();
      }
    });
  };

  var show_filter = function (field, options) {
    var default_options = {
      callback_func: function () {},
      slowly: false,
      show_filter: true,
      hide_only: false
    };

    options = $.extend({}, default_options, options);

    var field_el = $('#filter_' +  field);
    if (field_el !== null) {
      if (!options.insert_after) {
        options.insert_after = last_visible_filter();
      }
      if (options.insert_after && options.show_filter) {
        // Move the filter down to appear after the last currently visible filter
        if (field_el.attr('id') !== options.insert_after.id) {
          field_el.detach();
          $('#' + options.insert_after.id).after(field_el);
        }
      }
      // the following command might be included into the callback_function (which is called after the ajax request) later
      var display_functor;
      if (options.show_filter) {
        options.slowly ? field_el.fadeIn('slow') : field_el.show();
        load_available_values_for_filter(field, options.callback_func);
        $('#rm_' + field).val(field); // set the value, so the serialized form will return this filter
        value_changed(field);
      } else {
        if (!options.slowly) {
          console.log('hiding for fade', field_el);
        }
        options.slowly ? field_el.fadeOut('slow') : field_el.hide();

        if (!options.hide_only) { // remember that this filter used to be selected
          field_el.removeAttr('data-selected');
        }
        $('#rm_' + field).val(""); // reset the value, so the serialized form will not return this filter
      }
      operator_changed(field, $("#operators\\[" + field + "\\]"));
      display_category($('#' + field_el.attr("data-label")));
    }
  };

  /**
   * Activates the filter with the given name.
   *
   * @param filter_name Name of the filter to be activated.
   */
  var add_filter = function (filter_name) {
    var field = filter_name;
    // do this immediately instead of in callback to avoid concurrency issues during testing
    select_option_enabled($('#add_filter_select'), filter_name, false);
    show_filter(field, { slowly: true });
  };

  var remove_filter = function (field, hide_only) {
    show_filter(field, { show_filter: false, hide_only: hide_only });
    select_option_enabled($("#add_filter_select"), field, true);
  };

  var last_visible_filter = function () {
    return $('.advanced-filters--filter:visible').last()[0];
  };

  /* Display the given category if any of its filters are visible. Otherwise hide it */
  var display_category = function (label) {
    if (label.length) {
      $('.advanced-filters--filter').each(function() {
        var filter = $(this);
        if (filter.is(':visible') && filter.attr("data-label") === label) {
          $(label).show();
          return;
        }
        $(label).hide();
      });
    }
  };

  var operator_changed = function (field, select) {
    var option_tag, arity, first;
    if (select === null) {
      return;
    }
    first = false;
    if (!select.attr("data-first")) {
      first = true;
      $(select).attr("data-first", "false");
    }
    option_tag = select.find('option[value="' + select.val() + '"]');
    arity = parseInt(option_tag.attr("data-arity"));
    change_argument_visibility(field, arity);
    if (option_tag.attr("data-forced")) {
      force_type(option_tag, first);
    }
  };

  // Overwrite to customize input enforcements.
  // option: 'option' HTMLElement
  // first: Boolean indicating whether the operator changed for the first time
  var force_type = function (option, first) {
    return true;
  };

  var value_changed = function (field) {
    var val, filter;
    val = $('#' + field + '_arg_1_val');
    filter = $('#filter_' + field);
    if (!val) {
      return;
    }
    if (val.value === '<<inactive>>') {
      filter.addClass('inactive-filter');
    } else {
      filter.removeClass('inactive-filter');
    }
  };

  var change_argument_visibility = function (field, arg_nr) {
    var params, i;
    params = [$('#' + field + '_arg_1'), $('#' + field + '_arg_2')];

    for (i = 0; i < 2; i += 1) {
      if (params[i] !== null) {
        if (arg_nr >= (i + 1) || arg_nr <= (-1 - i)) {
          params[i].show();
          params[i].children().show();
        } else {
          params[i].hide();
          params[i].children().hide();
        }
      }
    }
  };

  var select_option_enabled = function (box, value, state) {
    box.find("[value='" + value + "']").attr('disabled', !state);
  };

  var multi_select = function (select, multi) {
    select.attr('multiple', multi);
    if (multi) {
      select.attr('size', 4);
      // deselect first option if it's present
      if (select.find('option')[0]) {
        select.find('option').first().attr('selected', false);
      }
    } else {
      select.attr('size', 1);
    }
  };

  var toggle_multi_select = function (select) {
    multi_select(select, !select.attr('multiple'));
  };

  var visible_filters = function () {
    return _.map($("#filter_table .advanced-filters--filter:visible"), function(filter) {
      return $(filter).attr("data-filter-name");
    });
  };

  var clear = function () {
    _.each(visible_filters(), function (filter) {
      remove_filter(filter);
    });
  };

  // Select the given values of the selectBox.
  // Toggle multi-select state of the selectBox depending on how many values were given.
  var select_values = function(selectBox, values_to_select) {
    multi_select(selectBox, values_to_select.length > 1);
    selectBox.val(values_to_select);
  };

  var exists = function (filter) {
    return visible_filters().indexOf(filter) > 0;
  };

  return {
    add_filter: add_filter,
    clear: clear,
    exists: exists,
    operator_changed: operator_changed,
    remove_filter: remove_filter,
    select_option_enabled: select_option_enabled,
    select_values: select_values,
    toggle_multi_select: toggle_multi_select,
    value_changed: value_changed
  };
}(jQuery);

(function($) {
  Reporting.onload(function () {
    if ($("#add_filter_select")) {
      $("#add_filter_select").on("change", function () {
        if (!(Reporting.Filters.exists(this.value))) {
          Reporting.Filters.add_filter(this.value);
          var new_filter = this.value;
          this.selectedIndex = 0;
          setTimeout(function () {
            $('#operators\\['+ new_filter +'\\]').focus();
          }, 300);
        }
      });
    }

    $(".filter_rem")
      .on("click", function (event) {
        event.preventDefault();
        var filter_name = $(this).closest('li').attr("data-filter-name");
        Reporting.Filters.remove_filter(filter_name);
      })
      .on("keydown", function (event) {
        if (event.keyCode == 13 || event.keyCode == 32) {
          event.preventDefault();
          var filter_name = $(this).closest('li').attr("data-filter-name"),
              prevVisibleFilter = $(this).closest('li').prevAll(':visible').last().find('.advanced-filters--select');

          if (prevVisibleFilter.length > 0) {
            prevVisibleFilter.focus();
          } else {
            $('#filters > legend a')[0].focus();
          }
          Reporting.Filters.remove_filter(filter_name);
        }
      });

    $(".filter_operator")
      .on("change", function (evt) {
        var filter_name = $(this).attr("data-filter-name");
        Reporting.Filters.operator_changed(filter_name, $(this));
        const argVal = $('#' + filter_name + "_arg_1_val")[0];
        if (argVal) {
          Reporting.fireEvent(argVal, "change");
        }
      });

    $(".filter_multi-select")
      .on("click", function () {
        var filter_name = $(this).attr("data-filter-name");
        Reporting.Filters.toggle_multi_select($('#' + filter_name + '_arg_1_val'));
      });

    $(".advanced-filters--filter-value .filter-value").each(function () {
      var select = $(this);
      var select_value = select.val();

      // Don't try to set multiple on the autocompleters, it is already multi-select
      // and will trigger weird change detection cycles
      if (this.tagName.toLowerCase() !== 'opce-project-autocompleter') {
        select.attr('multiple', select_value && select_value.length > 1);
      }

      select.on("change", function (evt) {
        var filter_name = $(this).closest('li').attr("data-filter-name");
        Reporting.Filters.value_changed(filter_name);
      });
    });
  });
})(jQuery);
