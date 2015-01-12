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

  restore_dependent_filters: function(filter_name) {
    $$("li.work-packages-filters--filter[data-filter-name=" + filter_name + "] select.filter-value").each(function(selectBox) {
      var activateNext = function(dependent) {
        if (!dependent) return;
        Reporting.RestoreQuery.restore_dependent_filters(dependent);
      };
      if (selectBox.hasAttribute('data-initially-selected')) {
        var selected_values = selectBox.readAttribute('data-initially-selected').replace(/'/g, '"').evalJSON(true);
        Reporting.Filters.select_values(selectBox, selected_values);
        Reporting.Filters.value_changed(filter_name);
      }
      if (selectBox.getValue() !== '<<inactive>>') {
        Reporting.Filters.activate_dependents(selectBox, activateNext);
      }
    });
  },

  restore_filters: function () {
    var deps = $$('.filters-select.filter-value').each(function(select) {
      var tr = select.up('li');
      if (tr.visible()) {
        var filter = tr.readAttribute('data-filter-name');
        var dependent = select.readAttribute('data-dependent');
        if (filter && dependent) {
          Reporting.Filters.remove_filter(filter, false);
        }
      }
    });

    $$("tr[data-selected=true]").each(function (e) {
      var select = e.down(".work-packages-filters--filter-value select");
      if (select && select.hasAttribute("data-dependent")) return;
      var filter_name = e.getAttribute("data-filter-name");
      var on_complete = function() {
        Reporting.RestoreQuery.restore_dependent_filters(filter_name);
      };
      Reporting.Filters.add_filter(filter_name, false, on_complete);
    });
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
