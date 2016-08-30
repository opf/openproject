//-- copyright
// ReportingEngine
//
// Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
        set_filter_value_widths(100);
      } else {
        options.slowly ? field_el.fadeOut('slow') : field_el.hide();

        if (!options.hide_only) { // remember that this filter used to be selected
          field_el.removeAttr('data-selected');
        }
        $('#rm_' + field).val(""); // reset the value, so the serialized form will not return this filter
        set_filter_value_widths(5000);
      }
      operator_changed(field, $("#operators\\[" + field + "\\]"));
      display_category($('#' + field_el.attr("data-label")));
    }
  };

  /**
   * Activates the filter with the given name and loads dependent filters if necessary.
   *
   * @param filter_name Name of the filter to be activated.
   */
  var add_filter = function (filter_name, activate_dependent, on_complete) {
    var field = filter_name;
    if (activate_dependent === undefined) {
      activate_dependent = true;
    }
    if (on_complete === undefined) {
      on_complete = function() { };
    }
    // do this immediately instead of in callback to avoid concurrency issues during testing
    select_option_enabled($('#add_filter_select'), filter_name, false);
    show_filter(field, { slowly: true, callback_func: function() {
        if (activate_dependent) {
          activate_dependents($('#' + field + "_arg_1_val"));
        }
        on_complete();
      }
    });
  };

  // TODO: remove dependents handling

  var remove_filter = function (field, hide_only) {
    show_filter(field, { show_filter: false, hide_only: hide_only });
    var dependent = get_dependents($('#' + field + '_arg_1_val'), false).find(function(d) {
      return visible_filters().include(d);
    });
    if (dependent !== undefined) {
      remove_filter(dependent);
    }
    select_option_enabled($("#add_filter_select"), field, true);
  };

  /*
    Smoothly sets the width of currently displayed filters.
    Params:
      delay:Int
        Time to wait before resizing the filters width */
  var set_filter_value_widths = function (delay) {
    window.clearTimeout(set_filter_value_widths_timeout);
    if (visible_filters().length > 0) {
      set_filter_value_widths_timeout = window.setTimeout(function () {
        var table_data = $('#filter_' + visible_filters()[0] + ' .advanced-filters--filter-value').first().parent();
        var current_width = table_data.width();
        var filters = $(".advanced-filters--filter");
        // First, reset all widths
        filters.css('width', 'auto');
        //filter_values.each(function (f) {
        //  $(f).up().style.width = "auto";
        //});
        // Now, get the current width
        // Any width will be fine, as the table layout makes all elements the same width
        var new_width = table_data.width();
        if (new_width < current_width) {
          // Set all widths to previous, so we can animate
          filters.css('width', current_width + 'px');
          //filter_values.each(function (f) {
          //  $(f).up().style.width = current_width + "px";
          //});
        }
        // Now, set all widths to be the widest
        if (new_width < current_width) {
          filters.animate('width', new_width + 'px');
        } else {
          filters.css('width', new_width + 'px');
        }
        //filter_values.each(function (f) {
        //  if (new_width < current_width) {
        //    $(f).up().morph("width: " + new_width + "px;");
        //  } else {
        //    $(f).up().style.width = new_width + "px";
        //  }
        //});
      }, delay);
    }
  };

  var set_filter_value_widths_timeout;

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

  // Returns an array of dependents of the given element
  // get_all -> Boolean: whether to return all dependends (even the
  //                     dependents of this filters dependents) or not
  var get_dependents = function (element, get_all) {
    var dependent_field = "data-all-dependents";
    if (get_all === false) {
      dependent_field = "data-next-dependents";
    }
    if (element.attr(dependent_field)) {
      return element.attr(dependent_field).replace(/'/g, '"').evalJSON(true);
    } else {
      return [];
    }
  };

  // Activate the first dependent of the changed filter, if it is not already active.
  // Afterwards, collect the visible filters from the dependents list and start
  // narrowing down their values.
  // Param: select [optional] - the select-box of the filter which should activate it's dependents
  var activate_dependents = function (selectBox, callbackWhenFinished) {
    var all_dependents,
        next_dependents,
        dependent,
        active_filters,
        source,
        tagName = selectBox.prop('tagName');

    if (selectBox === undefined || (selectBox.type && selectBox.type.toLowerCase() == 'change')) {
      selectBox = this;
    }
    if (tagName.toLowerCase() !== "select") {
      return; // only multi_value filters have dependents
    }
    if (callbackWhenFinished  === undefined) {
      callbackWhenFinished = function(dependent) { };
    }
    source = selectBox.attr("data-filter-name");
    all_dependents = get_dependents(selectBox);
    next_dependents = get_dependents(selectBox, false);
    dependent = which_dependent_shall_i_take(source, next_dependents);
    if (!dependent) {
      return;
    }
    active_filters = visible_filters();

    if (!active_filters.include(dependent)) {
      // in case we run into a situation where the dependent to show is not in the currently selected dependency chain
      // we have to remove all filters until we reach the source and add the new dependent
      if (next_dependents.any( function(d){ return active_filters.include(d) } )) {
        while (active_filters.last() !== source) {
          show_filter(active_filters.pop(1), { show_filter: false, slowly: true });
        }
      }
      show_filter(dependent, { slowly: true, insert_after: $(selectBox.up(".filter")) });
      // render filter inactive if possible to avoid unintended filtering
      $(dependent + '_arg_1_val').value = '<<inactive>>'
      operator_changed(dependent, $('operators[' + dependent + ']'));
      // Hide remove box of dependent
      $('rm_box_' + dependent).hide();
      // Remove border of dependent, so it "merges" with the filter before
      $('filter_' + dependent).addClassName("no-border");
      active_filters.unshift(dependent);
    }
    setTimeout(function () { // Make sure the newly shown filters are in the DOM
      var active_dependents = all_dependents.select(function (d) {
        return active_filters.include(d);
      });
      narrow_values(
        dependent_for(source),
        active_dependents,
        function() { callbackWhenFinished(dependent); }
      );
    }, 1);
  };

  // return an array of all filters that depend on the given filter plus the given filter
  var dependent_for = function(field) {
    var deps = $$('.advanced-filters--select[data-all-dependents]').findAll(function(selectBox) {
        return (selectBox.up('li').visible()) && get_dependents(selectBox).include(field)
      }).map(function(selectBox) {
        return selectBox.attr("data-filter-name");
      });
    return deps === undefined ? [ field ] : [ field ].concat(deps)
  };

  // Select the given values of the selectBox.
  // Toggle multi-select state of the selectBox depending on how many values were given.
  var select_values = function(selectBox, values_to_select) {
    multi_select(selectBox, values_to_select.length > 1);
    selectBox.val(values_to_select);
    //values_to_select.each(function (val) {
    //  var opt = selectBox.select("option[value='" + val + "']");
    //  if (opt.size() > 0) {
    //    opt.first().selected = true;
    //  }
    //});
  };

  var exists = function (filter) {
    return visible_filters().indexOf(filter) > 0;
  };

  // Narrow down the available values for the [dependents] of [sources].
  // This will narrow down for each dependent separately, adding each finished
  // dependent to the sources array and removing it from the dependents array.
  var narrow_values = function (sources, dependents, callbackWhenFinished) {
    if (sources.size() === 0 || dependents.size === 0 || dependents.first() === undefined) {
      return;
    }
    if (callbackWhenFinished  === undefined) {
      callbackWhenFinished = function() {};
    }
    var params = document.location.href.include('?') ? '&' : '?'
    params = params + "narrow_values=1&dependent=" + dependents.first();
    sources.each(function (filter) {
      params = params + "&sources[]=" + filter;
    });
    var targetUrl = document.location.href + params;
    var currentDependent = dependents.first();
    var updater = new Ajax.Request(targetUrl,
      {
        asynchronous: true,
        evalScripts: true,
        postBody: Reporting.Controls.serialize_settings_form(),
        onSuccess: function (response) {
          Reporting.clearFlash();
          if (response.responseJSON !== undefined) {
            var continue_narrowing = true;
            var selectBox = $(currentDependent + "_arg_1_val");
            var selected = selectBox.select("option").collect(function (sel) {
              if (sel.selected) {
                return sel.value;
              }
            }).compact();
            // remove old values
            $(selectBox).children().each(function (o) {
              o.remove();
            });
            // insert new values
            response.responseJSON.each(function (o) {
              var ary = [ (o === null ? "" : o) ].flatten();
              var label = ary.first();
              var value = ary.last();
              // cannot use .innerhtml due to IE wierdness
              $(selectBox).insert(new Element('option', {value: value}).update(label.escapeHTML()));
            });

            select_values(selectBox, selected);

            sources.push(currentDependent); // Add as last element
            dependents.splice(0, 1); // Delete first element
            // if we got no values besides the <<inactive>> value, do not show this selectBox
            if (!selectBox.select("option").any(function (opt) { return opt.value != '<<inactive>>' })) {
                show_filter(currentDependent, { show_filter: false });
                continue_narrowing = false;
            }
            // if the current filter is inactive, hide dependent - otherwise recurisvely narrow dependent values
            if (selectBox.value == '<<inactive>>') {
              value_changed(currentDependent);
              dependents.each(function (dependent) {
                show_filter(dependent, {
                  slowly: true,
                  show_filter: false });
              });
              continue_narrowing = false;
            }
            if (continue_narrowing) {
              narrow_values(sources, dependents);
            }
            callbackWhenFinished();
          }
        },
        onException: function (response, error) {
          if (console) {
            console.log(error);
          }
          Reporting.flash("Loading of filter values failed. Probably, the server is temporary offline for maintenance.");
          var selectBox = $(currentDependent + "_arg_1_val");
          $(selectBox).insert(new Element('option', {value: '<<inactive>>'}).update('Failed to load values.'));
        }
      }
    );
  };

  // This method may be overridden by the actual application to define custon behavior
  // If there are multiple possible dependents to follow.
  // The dependent to follow should be returned.
  var which_dependent_shall_i_take = function(source, dependents) {
    return dependents.first();
  };

  return {
    activate_dependents: activate_dependents,
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
        Reporting.fireEvent($('#' + filter_name + "_arg_1_val")[0], "change");
      });

    $(".filter_multi-select")
      .on("click", function () {
        var filter_name = $(this).attr("data-filter-name");
        Reporting.Filters.toggle_multi_select($('#' + filter_name + '_arg_1_val'));
      });

    $(".advanced-filters--filter-value .filter-value").each(function () {
      var select = $(this);
          select_value = select.val();

      select.attr('multiple', select_value && select_value.length > 1);

      select.on("change", function (evt) {
        var filter_name = $(this).closest('li').attr("data-filter-name");
        Reporting.Filters.value_changed(filter_name);
      });
    });

    $('.advanced-filters--select[data-all-dependents]').on("change", Reporting.Filters.activate_dependents);
  });
})(jQuery);
