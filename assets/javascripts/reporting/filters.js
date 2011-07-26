/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax, Element, Form */

Reporting.Filters = {
  load_available_values_for_filter:  function  (filter_name, callback_func) {
    var select, radio_options;
    select = $('' + filter_name + '_arg_1_val');
    //TODO: the following code ist cost report specific, we should refactor that to be general useful
    if (select !== null && select.readAttribute('data-loading') === "ajax" && select.childElements().length === 0) {
      Ajax.Updater({ success: select }, window.global_prefix + '/cost_reports/available_values', {
        parameters: { filter_name: filter_name },
        insertion: 'bottom',
        evalScripts: false,
        onCreate: function (a, b) {
          $('operators_' + filter_name).disable();
          $('' + filter_name + '_arg_1_val').disable();
        },
        onComplete: function (a, b) {
          $('operators_' + filter_name).enable();
          $('' + filter_name + '_arg_1_val').enable();
          callback_func();
        }
      });
      Reporting.Filters.multi_select(select, false);
    } else {
      callback_func();
    }
    // select first option by default
    if (select.tagName.toLowerCase() === "div") {
      // check if we might have a radio-box
      radio_options = $$('.' + filter_name + '_radio_option input');
      if (radio_options && radio_options.size() !== 0) {
        radio_options.first().checked = true;
      }
    } else if (select.tagName.toLowerCase() === "select") {
      select.selectedIndex = 0;
    }
  },

  show_filter: function (field, options) {
    if (options === undefined) {
      options = {};
    }
    if (options.callback_func === undefined) {
      options.callback_func = function () {};
    }
    if (options.slowly === undefined) {
      options.slowly = false;
    }
    if (options.show_filter === undefined) {
      options.show_filter = true;
    }
    var field_el = $('tr_' +  field);
    if (field_el !== null) {
      if (options.insert_after === undefined) {
        options.insert_after = Reporting.Filters.last_visible_filter();
      }
      if (options.insert_after !== undefined && options.show_filter) {
        // Move the filter down to appear after the last currently visible filter
        field_el.remove();
        options.insert_after.insert({after: field_el});
      }
      // the following command might be included into the callback_function (which is called after the ajax request) later
      var display_functor;
      if (options.show_filter) {
        (options.slowly ? Effect.Appear : Element.show)(field_el);
        Reporting.Filters.load_available_values_for_filter(field, options.callback_func);
        $('rm_' + field).value = field; // set the value, so the serialized form will return this filter
        Reporting.Filters.value_changed(field);
        Reporting.Filters.set_filter_value_widths(100);
      } else {
        (options.slowly ? Effect.Fade : Element.hide)(field_el);
        field_el.removeAttribute('data-selected');
        $('rm_' + field).value = ""; // reset the value, so the serialized form will not return this filter
        Reporting.Filters.set_filter_value_widths(5000);
      }
      Reporting.Filters.operator_changed(field, $("operators[" + field + "]"));
      Reporting.Filters.display_category($(field_el.getAttribute("data-label")));
    }
  },

  /*
    Smoothly sets the width of currently displayed filters.
    Params:
      delay:Int
        Time to wait before resizing the filters width */
  set_filter_value_widths: function (delay) {
    window.clearTimeout(Reporting.Filters.set_filter_value_widths_timeout);
    if (Reporting.Filters.visible_filters().size() > 0) {
      Reporting.Filters.set_filter_value_widths_timeout = window.setTimeout(function () {
        var table_data = $("tr_" + Reporting.Filters.visible_filters().first()).select(".filter_values").first().up();
        var current_width = table_data.getWidth();
        var filter_values = $($$(".filter_values"));
        // First, reset all widths
        filter_values.each(function (f) {
          $(f).up().style.width = "auto";
        });
        // Now, get the current width
        // Any width will be fine, as the table layout makes all elements the same width
        var new_width = table_data.getWidth();
        if (new_width < current_width) {
          // Set all widths to previous, so we can animate
          filter_values.each(function (f) {
            $(f).up().style.width = current_width + "px";
          });
        }
        // Now, set all widths to be the widest
        filter_values.each(function (f) {
          if (new_width < current_width) {
            $(f).up().morph("width: " + new_width + "px;");
          } else {
            $(f).up().style.width = new_width + "px";
          }
        });
      }, delay);
    }
  },
  set_filter_value_widths_timeout: undefined,

  last_visible_filter: function () {
    return $($$('.filter')).reverse().detect(function (f) {
      return f.visible();
    });
  },

  /* Display the given category if any of its filters are visible. Otherwise hide it */
  display_category: function (label) {
    if (label !== null) {
      var filters = $$('.filter');
      for (var i = 0; i < filters.length; i += 1) {
        if (filters[i].visible() && filters[i].getAttribute("data-label") === label) {
          Element.show(label);
          return;
        }
      }
      Element.hide(label);
    }
  },

  operator_changed: function (field, select) {
    var option_tag, arity;
    if (select === null) {
      return;
    }
    option_tag = select.options[select.selectedIndex];
    arity = parseInt(option_tag.getAttribute("data-arity"), 10);
    Reporting.Filters.change_argument_visibility(field, arity);
  },

  value_changed: function (field) {
    var val, tr;
    val = $(field + '_arg_1_val');
    tr = $('tr_' + field);
    if (!val) {
      return;
    }
    if (val.value === '<<inactive>>') {
      tr.addClassName('inactive-filter');
    } else {
      tr.removeClassName('inactive-filter');
    }
  },

  change_argument_visibility: function (field, arg_nr) {
    var params, i;
    params = [$(field + '_arg_1'), $(field + '_arg_2')];

    for (i = 0; i < 2; i += 1) {
      if (params[i] !== null) {
        if (arg_nr >= (i + 1) || arg_nr <= (-1 - i)) {
          params[i].show();
        } else {
          params[i].hide();
        }
      }
    }
  },

  add_filter: function (select) {
    var field;
    field = select.value;
    Reporting.Filters.show_filter(field, { slowly: true });
    select.selectedIndex = 0;
    Reporting.Filters.select_option_enabled(select, field, false);
  },

  select_option_enabled: function (box, value, state) {
    var option = box.select("[value='" + value + "']").first();
    if (option !== undefined) {
      option.disabled = !state;
    }
  },

  multi_select: function (select, multi) {
    select.multiple = multi;
    if (multi) {
      select.size = 4;
      // deselect first option
      select.options[0].selected = false;
    } else {
      select.size = 1;
    }
  },

  toggle_multi_select: function (select) {
    Reporting.Filters.multi_select(select, !select.multiple);
  },

  remove_filter: function (field) {
    Reporting.Filters.show_filter(field, { show_filter: false });
    var dependent = Reporting.Filters.get_dependents($(field + '_arg_1_val'), false).find(function(d) {
      return Reporting.Filters.visible_filters().include(d);
    });
    if (dependent !== undefined) {
      Reporting.Filters.remove_filter(dependent);
    }
    Reporting.Filters.select_option_enabled($("add_filter_select"), field, true);
  },

  visible_filters: function () {
    return $("filter_table").select("tr").select(function (tr) {
      return tr.visible() === true;
    }).collect(function (filter) {
      return filter.getAttribute("data-filter-name");
    });
  },

  clear: function () {
    Reporting.Filters.visible_filters().each(function (filter) {
      Reporting.Filters.remove_filter(filter);
    });
  },

  // Returns an array of dependents of the given element
  // get_all -> Boolean: whether to return all dependends (even the
  //                     dependents of this filters dependents) or not
  get_dependents: function (element, get_all) {
    var dependent_field = "data-all-dependents";
    if (get_all === false) {
      dependent_field = "data-next-dependents";
    }
    if (element.hasAttribute(dependent_field)) {
      return element.getAttribute(dependent_field).replace(/'/g, '"').evalJSON(true);
    } else {
      return [];
    }
  },

  // Activate the first dependent of the changed filter, if it is not already active.
  // Afterwards, collect the visible filters from the dependents list and start
  // narrowing down their values.
  // Param: select [optional] - the select-box of the filter which should activate it's dependents
  activate_dependents: function (selectBox, callbackWhenFinished) {
    var all_dependents, next_dependents, dependent, active_filters, source;
    if (selectBox  === undefined || selectBox.type.toLowerCase() == 'change') {
      selectBox = this;
    }
    if (callbackWhenFinished  === undefined) {
      callbackWhenFinished = function() {};
    }
    source = selectBox.getAttribute("data-filter-name");
    all_dependents = Reporting.Filters.get_dependents(selectBox);
    next_dependents = Reporting.Filters.get_dependents(selectBox, false);
    dependent = Reporting.Filters.which_dependent_shall_i_take(source, next_dependents);
    active_filters = Reporting.Filters.visible_filters();

    if (!active_filters.include(dependent)) {
      // in case we run into a situation where the dependent to show is not in the currently selected dependency chain
      // we have to remove all filters until we reach the source and add the new dependent
      if (next_dependents.any( function(d){ return active_filters.include(d) } )) {
        while (active_filters.last() !== source) {
          Reporting.Filters.show_filter(active_filters.pop(1), { show_filter: false, slowly: true });
        }
      }
      Reporting.Filters.show_filter(dependent, { slowly: true, insert_after: $(selectBox.up(".filter")) });
      // render filter inactive if possible to avoid unintended filtering
      $(dependent + '_arg_1_val').value = '<<inactive>>'
      Reporting.Filters.operator_changed(dependent, $('operators[' + dependent + ']'));
      // Hide remove box of dependent
      $('rm_box_' + dependent).hide();
      // Remove border of dependent, so it "merges" with the filter before
      $('tr_' + dependent).addClassName("no-border");
      active_filters.unshift(dependent);
    }
    setTimeout(function () { // Make sure the newly shown filters are in the DOM
      var active_dependents = all_dependents.select(function (d) {
        return active_filters.include(d);
      });
      Reporting.Filters.narrow_values(Reporting.Filters.dependent_for(source), active_dependents, callbackWhenFinished);
    }, 1);
  },

  // return an array of all filters that depend on the given filter plus the given filter
  dependent_for: function(field) {
    var deps = $$('.filters-select[data-all-dependents]').findAll(function(selectBox) {
        return selectBox.up('tr').visible() && Reporting.Filters.get_dependents(selectBox).include(field)
      }).map(function(selectBox) {
        return selectBox.getAttribute("data-filter-name");
      });
    return deps === undefined ? [ field ] : [ field ].concat(deps)
  },

  // Select the given values of the selectBox.
  // Toggle multi-select state of the selectBox depending on how many values were given.
  select_values: function(selectBox, values_to_select) {
    Reporting.Filters.multi_select(selectBox, values_to_select.size() > 1);
    values_to_select.each(function (val) {
      var opt = selectBox.select("option[value='" + val + "']");
      if (opt.size() === 1) {
        opt.first().selected = true;
      }
    });
  },

  exists: function (filter) {
    return Reporting.Filters.visible_filters().include(filter);
  },

  // Narrow down the available values for the [dependents] of [sources].
  // This will narrow down for each dependent separately, adding each finished
  // dependent to the sources array and removing it from the dependents array.
  narrow_values: function (sources, dependents, callbackWhenFinished) {
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
            $(selectBox).childElements().each(function (o) {
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
            Reporting.Filters.select_values(selectBox, selected);
            sources.push(currentDependent); // Add as last element
            dependents.splice(0, 1); // Delete first element
            // if we got no values besides the <<inactive>> value, do not show this selectBox
            if (!selectBox.select("option").any(function (opt) { return opt.value != '<<inactive>>' })) {
                Reporting.Filters.show_filter(currentDependent, { show_filter: false });
                continue_narrowing = false;
            }
            // if the current filter is inactive, hide dependent - otherwise recurisvely narrow dependent values
            if (selectBox.value == '<<inactive>>') {
              Reporting.Filters.value_changed(currentDependent);
              dependents.each(function (dependent) {
                Reporting.Filters.show_filter(dependent, {
                  slowly: true,
                  show_filter: false });
              });
              continue_narrowing = false;
            }
            if (continue_narrowing) {
              Reporting.Filters.narrow_values(sources, dependents);
            }
          }
          callbackWhenFinished();
        },
        onException: function (response, error) {
          Reporting.flash("Loading of filter values failed. Probably, the server is temporary offline for maintenance.");
          var selectBox = $(currentDependent + "_arg_1_val");
          $(selectBox).insert(new Element('option', {value: '<<inactive>>'}).update('Failed to load values.'));
        }
      }
    );
  },

  // This method may be overridden by the actual application to define custon behavior
  // If there are multiple possible dependents to follow.
  // The dependent to follow should be returned.
  which_dependent_shall_i_take: function(source, dependents) {
    return dependents.first();
  }
};

Reporting.onload(function () {
  if ($("add_filter_select")) {
    $("add_filter_select").observe("change", function () {
      if (!(Reporting.Filters.exists(this.value))) {
        Reporting.Filters.add_filter(this);
      };
    });
  }

  $$(".filter_rem").each(function (e) {
    e.observe("click", function () {
      var filter_name = this.up('tr').getAttribute("data-filter-name");
      Reporting.Filters.remove_filter(filter_name);
    });
  });
  $$(".filter_operator").each(function (e) {
    e.observe("change", function (evt) {
      var filter_name = this.getAttribute("data-filter-name");
      Reporting.Filters.operator_changed(filter_name, this);
      Reporting.fireEvent($(filter_name + "_arg_1_val"), "change");
    });
  });
  $$(".filter_multi-select").each(function (e) {
    e.observe("click", function () {
      Reporting.Filters.toggle_multi_select($(this.getAttribute("data-filter-name") + '_arg_1_val'));
    });
  });
  $$(".filters-select").each(function (s) {
    var selected_size = Array.from(s.options).findAll(function (o) {
      return o.selected === true;
    }).size();
    s.multiple = (selected_size > 1);
    s.observe("change", function (evt) {
    var filter_name = this.up('tr').getAttribute("data-filter-name");
    Reporting.Filters.value_changed(filter_name);
    });
  });
  $$('.filters-select[data-all-dependents]').each(function (dependency) {
    dependency.observe("change", Reporting.Filters.activate_dependents);
  });
});
