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

Reporting.RestoreQuery = function($){

  var select_operator = function (field, operator) {
    var select, i;
    select = $("#operators_" + field);
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
  };

  var disable_select_option = function (select, field) {
    for (var i = 0; i < select.options.length; i += 1) {
      if (select.options[i].value === field) {
        select.options[i].disabled = true;
        break;
      }
    }
  };

  var restore_dependent_filters = function(filter_name) {
    $("li.advanced-filters--filter[data-filter-name=" + filter_name + "] select.filter-value").each(function() {
      selectBox = $(this);
      var activateNext = function(dependent) {
        if (!dependent) return;
        restore_dependent_filters(dependent);
      };
      if (selectBox.attr('data-initially-selected')) {
        var selected_values = selectBox.attr('data-initially-selected').replace(/'/g, '"').evalJSON(true);
        Reporting.Filters.select_values(selectBox, selected_values);
        Reporting.Filters.value_changed(filter_name);
      }
      if (selectBox.val() !== '<<inactive>>') {
        Reporting.Filters.activate_dependents(selectBox, activateNext);
      }
    });
  };

  var restore_filters = function () {
    var deps = _.each($('.advanced-filters--select.filter-value'), function(select) {
      var jselect = $(select),
          tr = jselect.closest('li');

      if (tr.visible()) {
        var filter = tr.attr('data-filter-name');
        var dependent = jselect.attr('data-dependent');

        if (filter && dependent) {
          Reporting.Filters.remove_filter(filter, false);
        }
      }
    });

    _.each($("li.advanced-filters--filter[data-selected=true]"), function (e) {
      var filter = $(e),
          select = filter.find(".advanced-filters--filter-value select");
      if (select && select.attr("data-dependent")) return;
      var filter_name = filter.attr("data-filter-name");
      var on_complete = function() {
        restore_dependent_filters(filter_name);
      };
      Reporting.Filters.add_filter(filter_name, false, on_complete);
    });
  };

  var restore_group_bys = function () {
    _.each(Reporting.GroupBys.group_by_container_ids(), function(id) {
      var container = $('#' + id),
          selected_containers = container.attr('data-initially-selected'),
          selected_groups;


      if (selected_containers) {
        selected_groups = $.parseJSON(selected_containers.replace(/'/g, '"'));
        _.each(selected_groups, function(group_and_label) {
          var group, label;
          group = group_and_label[0];
          label = group_and_label[1];
          Reporting.GroupBys.add_group_by(group, label, container);
        });
      }
    });
  };

  return {
    restore_group_bys: restore_group_bys,
    restore_filters: restore_filters
  };
}(jQuery);

Reporting.onload(function () {
  Reporting.RestoreQuery.restore_group_bys();
  Reporting.RestoreQuery.restore_filters();
});
