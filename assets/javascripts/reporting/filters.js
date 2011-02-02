/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax, Element */

Reporting.Filters = {
  load_available_values_for_filter:  function  (filter_name, callback_func) {
    var select;
    select = $('' + filter_name + '_arg_1_val');
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
  },

  show_filter: function (field, options) {
    if (options === undefined) {
      options = {};
    }
    if (options.callback_func === undefined) {
      options.callback_func = function () {};
    }
    if (options.slowly === undefined) {
      options.slowly = true;
    }
    if (options.show_filter === undefined) {
      options.show_filter = true;
    }
    var field_el = $('tr_' +  field);
    if (field_el !== null) {
      Reporting.Filters.load_available_values_for_filter(field, options.callback_func);
      // the following command might be included into the callback_function (which is called after the ajax request) later
      $('rm_' + field).value = field;
      var display_functor;
      if (options.show_filter) {
        display_functor = options.slowly ? Effect.Appear : Element.show;
      } else {
        display_functor = options.slowly ? Effect.Fade : Element.hide;
      }
      display_functor(field_el);
      Reporting.Filters.operator_changed(field, $("operators_" + field));
      Reporting.Filters.display_category($(field_el.getAttribute("data-label")));
    }
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
    Reporting.Filters.show_filter(field);
    select.selectedIndex = 0;
    Reporting.Filters.select_option_enabled(select, field, false);
  },

  select_option_enabled: function (box, value, state) {
    box.select("[value='" + value + "']").first().disabled = !state;
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
    Reporting.Filters.select_option_enabled($("add_filter_select"), field, true);
  }
};

Reporting.onload(function () {
  $("add_filter_select").observe("change", function () {
    Reporting.Filters.add_filter(this);
  });
  $$(".filter_rem").each(function (e) {
    e.observe("click", function () {
      var filter_name = this.getAttribute("data-filter-name");
      Reporting.Filters.remove_filter(filter_name);
    });
  });
  $$(".filter_operator").each(function (e) {
    e.observe("change", function () {
      var filter_name = this.getAttribute("data-filter-name");
      Reporting.Filters.operator_changed(filter_name, this);
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
  });
});
