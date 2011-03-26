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

  // This is called the first time the report loads.
  // Params:
  //   elements: Array of visible filter-select-boxes that have dependents
  // (and possibly are dependents themselfes)
  initialize_load_dependent_filters: function(elements) {
    var filters_to_load, dependent_filters;
    dependent_filters = elements.findAll(function (select) { return select.value == '<<inactive>>' });
    filters_to_load   = elements.reject( function (select) { return select.value == '<<inactive>>' });
    // Filters which are <<inactive>> are probably dependents themselfes, so remove and forget them for now.
    // This is OK as they get reloaded later
    dependent_filters.each(function(select) {
      Reporting.Filters.remove_filter(select.up('tr').readAttribute("data-filter-name"));
    });
    // For each dependent filter we reload its dependent chain
    filters_to_load.each(function(selectBox) {
        var sources, selected_values;
        Reporting.Filters.activate_dependents(selectBox, function() {
          sources = Reporting.Filters.get_dependents(selectBox).collect(function(field) {
            return $('tr_' + field).select('.filter_values select').first();
          });
          sources.each(function(source) {
            if (source.hasAttribute('data-initially-selected')) {
              selected_values = source.readAttribute('data-initially-selected').replace(/'/g, '"').evalJSON(true);
              Reporting.Filters.select_values(source, selected_values);
              Reporting.Filters.value_changed(source.up('tr').readAttribute("data-filter-name"));
            }
          });
          if (sources.reject( function (select) { return select.value == '<<inactive>>' }).size() == 0) {
            Reporting.Filters.activate_dependents(selectBox);
          }
          else {
            Reporting.RestoreQuery.initialize_load_dependent_filters(sources);
          }
        });
    });
  },

  restore_filters: function () {
    // FIXME: rm_xxx values for filters have to be set after re-displaying them
    $$("tr[data-selected=true]").each(function (e) {
      var rm_box = e.select("input[id^=rm]").first();
      var filter_name = e.getAttribute("data-filter-name");
      rm_box.value = filter_name;
      Reporting.Filters.select_option_enabled($("add_filter_select"), filter_name, false);
    });
    // restore values of dependent filters
    Reporting.RestoreQuery.initialize_load_dependent_filters($$('.filters-select[data-dependents]').findAll(function(select) {
      return select.up('tr').visible()
    }));
  },

  restore_group_bys: function () {
    Reporting.GroupBys.group_by_container_ids().each(function(id) {
      var container, selected_groups;
      container = $(id);
      if (container.hasAttribute('data-initially-selected')) {
        selected_groups = container.readAttribute('data-initially-selected').replace(/'/g, '"').evalJSON(true);
        selected_groups.each(function(group_and_label) {
          var group, label;
          group = group_and_label[0];
          label = group_and_label[1];
          Reporting.GroupBys.add_group_by(group, label, container);
        });
      }
    });
  }
};

Reporting.onload(function () {
  Reporting.RestoreQuery.restore_group_bys();
  Reporting.RestoreQuery.restore_filters();
});
