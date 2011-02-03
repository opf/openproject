/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax */

Reporting.RestoreQuery = {
  restore_filters: function () {
    $('filter_table').select("tr").select(function (row) {
      return $(row).getAttribute("data-selected") === "true";
    }).each(function (row) {
      var field = row.className;
      Reporting.Filters.show_filter(field);
      Reporting.Filters.select_option_enabled($("add_filter_select"), field, false);
    });
  },

  select_operator: function (field, operator) {
    var select, i;
    select = $("operators_" + field);
    if (select === null) {
      return; // there is no such operator select field
    }
    for (i = 0; i < select.options.length; i += 1) {
      if (select.options[i].value === operator) {
        select.selectedIndex = i;
        break;
      }
    }
    Reporting.Filters.operator_changed(field, select);
  },

  disable_select_option: function (select, field) {
    for (var i = 0; i < select.options.length; i += 1) {
      if (select.options[i].value === field) {
        select.options[i].disabled = true;
        break;
      }
    }
  },

  show_group_by: function (group_by, target) {
    $('group_by_container').select("");
    var source, group_option, i;
    source = $("group_by_container");
    group_option = null;
    // find group_by option-tag in target select-box
    for (i = 0; i < source.options.length; i += 1) {
      if (source.options[i].value === group_by) {
        group_option = source.options[i];
        source.options[i] = null;
        break;
      }
    }
    // die if the appropriate option-tag can not be found
    if (group_option === null) {
      return;
    }
    // move the option-tag to the taget select-box while keepings its data
    target.options[target.length] = group_option;
  },

  restore_group_bys: function () {
    // Activate recent group_bys on loading
    var group_bys = $('group_by_container').select("option")
    .select(function (group_by) {
      return $(group_by).hasAttribute("data-selected-axis");
    }).sortBy(function (group_by) {
      return $(group_by).getAttribute("data-selected-index");
    }).each(function (group_by) {
      var axis = $(group_by).getAttribute("data-selected-axis");
      var name = $(group_by).getAttribute("value");
      Reporting.RestoreQuery.show_group_by(name, $('group_by_' + axis + 's'));
    });
  }
};

Reporting.onload(function () {
  Reporting.RestoreQuery.restore_group_bys();
});
