/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax */

Reporting.RestoreQuery = {

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
    $('group_by_container').select("option")
    .select(function (group_by) {
      return $(group_by).hasAttribute("data-selected-axis");
    }).sortBy(function (group_by) {
      return $(group_by).getAttribute("data-selected-index");
    }).each(function (group_by) {
      var axis = $(group_by).getAttribute("data-selected-axis");
      var name = $(group_by).getAttribute("value");
      Reporting.RestoreQuery.show_group_by(name, $('group_by_' + axis + 's'));
    });
  },

  restore_filters: function () {
    // FIXME: rm_xxx values for filters have to be set after re-displaying them
    $$("tr[data-selected=true]").each(function (e) {
      var rm_box = e.select("input[id^=rm]").first();
      rm_box.value = rm_box.getAttribute("data-filter-name");
    });
  }
};

Reporting.onload(function () {
  Reporting.RestoreQuery.restore_group_bys();
  Reporting.RestoreQuery.restore_filters();
});
