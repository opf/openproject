//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax, Element, selectAllOptions, Form */

Reporting.Controls = function($){
  var toggle_delete_form = function (e) {
    e.preventDefault();

    var offset = $('#query-icon-delete').offsetLeft;
    $('#delete_form').css("left", offset + "px").toggle();
  };

  var toggle_save_as_form = function (e) {
    e.preventDefault();

    var offset = $('#query-icon-save-as').offsetLeft;
    $('#save_as_form')
      .css('left',  offset + 'px')
      .toggle();
  };

  var clear_query = function (e) {
    e.preventDefault();

    Reporting.Filters.clear();
    Reporting.GroupBys.clear();
  };

  var send_settings_data = function (targetUrl, callback, failureCallback) {
    if (!failureCallback) {
      failureCallback = default_failure_callback;
    }
    Reporting.clearFlash();

    $.ajax({
      url: targetUrl,
      method: 'POST',
      data: serialize_settings_form(),
      beforeSend: function () {
        $('#ajax-indicator').show();
      },
      error: failureCallback,
      success: callback
    });
  };

  var serialize_settings_form = function() {
    var ret_str, grouping_str;
    ret_str = $('#query_form').serialize();
    grouping_str = _.reduce(['rows', 'columns'], function(grouping, type) {
      var element_map = _.map($('#group-by--' + type + ' .group-by--selected-element'), function(group_by) {
        return 'groups[' + type + '][]=' + $(group_by).attr('data-group-by');
      });

      return grouping + _.reduce(element_map, function(all_group_str, group_str) {
        return all_group_str + '&' + group_str;
      }, '');
    }, '');

    if (grouping_str.length > 0) {
      ret_str += grouping_str;
    }
    return ret_str;
  };

  var attach_settings_callback = function (element, callback) {
    if (element === null) {
      return;
    }
    failureCallback = function (response) {
      $('#result-table').html("");

      default_failure_callback(response);
    };

    element.on('click', function (e) {
      e.preventDefault();
      send_settings_data($(this).attr("data-target"), callback, failureCallback);
    });
  };

  var observe_click = function (element_id, callback) {
    $('#' + element_id).on('click', callback);
  };

  var update_result_table = function (response) {
    $('#result-table').html(response);

    window.OpenProject.pluginContext
      .valuesPromise()
      .then((context) => {
        context.bootstrap(document.getElementById('result-table'));
      });
  };

  var default_failure_callback = function (response) {
    if (response.status >= 400 && response.status < 500) {
      Reporting.flash(response.responseText);
    } else {
      Reporting.flash(I18n.t("js.reporting_engine.label_response_error"));
    }
  };

  return {
    attach_settings_callback: attach_settings_callback,
    clear_query: clear_query,
    observe_click: observe_click,
    update_result_table: update_result_table,
    toggle_delete_form: toggle_delete_form,
    toggle_save_as_form: toggle_save_as_form
  };
}(jQuery);

(function($) {
  Reporting.onload(function () {
    if ($('#query_saved_name').length) {
      // don't concern ourselves with new queries
      if ($('#query_saved_name').attr("data-is_new")) {
        if ($('#query-icon-delete').length) {
          Reporting.Controls.observe_click("query-icon-delete", Reporting.Controls.toggle_delete_form);
          Reporting.Controls.observe_click("query-icon-delete-cancel", Reporting.Controls.toggle_delete_form);
          $('#delete_form').hide();
        }

        if ($("#query-breadcrumb-save").length) {
          // When saving an update of an exisiting query or apply filters, we replace the table on success
          Reporting.Controls.attach_settings_callback($("#query-breadcrumb-save"), Reporting.Controls.update_result_table);
        }
      }
    }

    Reporting.Controls.observe_click("query-icon-save-as", Reporting.Controls.toggle_save_as_form);
    Reporting.Controls.observe_click("query-icon-save-as-cancel", Reporting.Controls.toggle_save_as_form);

    $('#save_as_form').hide();

    // When saving a new query, the success-response is the new saved query's url -> redirect to that
    Reporting.Controls.attach_settings_callback($("#query-icon-save-button"), function (newLocation) {
      document.location = newLocation;
    });
    // When saving an update of an exisiting query or apply filters, we replace the table on success
    Reporting.Controls.attach_settings_callback($("#query-icon-apply-button"), Reporting.Controls.update_result_table);
    Reporting.Controls.observe_click('query-link-clear', Reporting.Controls.clear_query);
  });
})(jQuery);
