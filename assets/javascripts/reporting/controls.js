/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax, Element, selectAllOptions, Form */

Reporting.Controls = {
  query_name_editor: function (target_id) {
    var target = $(target_id);
    var isPublic = target.getAttribute("data-is_public") === "true";
    var updateUrl = target.getAttribute("data-update-url");
    var translations = target.getAttribute("data-translations");
    if (translations.isJSON()) {
      translations = translations.evalJSON(true);
    }
    if (translations === undefined) {
      translations = {};
    }
    if (translations.rename === undefined) {
      translations.rename = 'ok';
    }
    if (translations.cancel === undefined) {
      translations.cancel = 'cancel';
    }
    if (translations.saving === undefined) {
      translations.saving = 'Saving...';
    }
    if (translations.loading === undefined) {
      translations.loading = 'Loading...';
    }
    if (translations.clickToEdit === undefined) {
      translations.loading = 'Click to edit';
    }

    var editor = new Ajax.InPlaceEditor(target_id, updateUrl, {
      callback: function (form, value) {
        return  'query_name=' + encodeURIComponent(value);
      },
      okControl: 'button',
      cancelControl: 'button',
      externalControl: 'query-name-edit-button',
      okText: translations.rename,
      cancelText: translations.cancel,
      savingText: translations.saving,
      loadingText: translations.loading,
      clickToEditText: translations.clickToEdit,
      onFailure: function (editor, response) {
        Reporting.flash(response.responseText);
      }
    });
  },

  toggle_delete_form: function (e) {
    var offset = $('query-icon-delete').positionedOffset().left;
    $('delete_form').setStyle("left: " + offset + "px").toggle();
    e.preventDefault();
  },

  toggle_save_as_form: function (e) {
    var offset = $('query-icon-save-as').positionedOffset().left;
    $('save_as_form').setStyle("left: " + offset + "px").toggle();
    e.preventDefault();
  },

  clear_query: function (e) {
    Reporting.Filters.clear();
    Reporting.GroupBys.clear();
    e.preventDefault();
  },

  send_settings_data: function (targetUrl, callback, failureCallback) {
    if (failureCallback === undefined) {
      failureCallback = Reporting.Controls.default_failure_callback;
    }
    Reporting.clearFlash();
    new Ajax.Request(
      targetUrl,
      { asynchronous: true,
        evalScripts: true,
        postBody: Reporting.Controls.serialize_settings_form(),
        onSuccess: callback,
        onFailure: failureCallback });
  },

  serialize_settings_form: function() {
    var ret_str, grouping_str;
    ret_str = Form.serialize('query_form');
    grouping_str = $w('rows columns').inject('', function(grouping, type) {
      return grouping + $('group_by_' + type).select('.group_by_element').map(function(group_by) {
        return 'groups[' + type + '][]=' + group_by.readAttribute('data-group-by');
      }).inject('', function(all_group_str, group_str) {
        return all_group_str + '&' + group_str;
      });
    });
    if (grouping_str.length > 0) {
      ret_str += grouping_str;
    }
    return ret_str;
  },

  attach_settings_callback: function (element, callback) {
    failureCallback = function (response) {
      $('result-table').update("");
      Reporting.Controls.default_failure_callback(response);
    };
    element.observe("click", function (e) {
      Reporting.Controls.send_settings_data(this.getAttribute("data-target"), callback, failureCallback);
      e.preventDefault();
    });
  },

  observe_click: function (element_id, callback) {
    var el = $(element_id);
    if (el !== null && el !== undefined) {
      el.observe("click", callback);
    }
  },

  update_result_table: function (response) {
    $('result-table').update(response.responseText);
    Reporting.Progress.confirm_question();
  },

  default_failure_callback: function (response) {
    if (response.status >= 400 && response.status < 500) {
      Reporting.flash(response.responseText);
    } else {
      Reporting.flash("There was an error getting the results. The administrator has been informed.");
    }
  }
};

Reporting.onload(function () {
  if ($('query_saved_name').getAttribute("data-update-url") !== null) {
    Reporting.Controls.query_name_editor('query_saved_name');
  }
  // don't concern ourselves with new queries
  if ($('query_saved_name').getAttribute("data-is_new") !== null) {
    if ($('query-icon-delete') !== null) {
      Reporting.Controls.observe_click("query-icon-delete", Reporting.Controls.toggle_delete_form);
      Reporting.Controls.observe_click("query-icon-delete-cancel", Reporting.Controls.toggle_delete_form);
      $('delete_form').hide();
    }

    if ($("query-breadcrumb-save") !== null) {
      // When saving an update of an exisiting query or apply filters, we replace the table on success
      Reporting.Controls.attach_settings_callback($("query-breadcrumb-save"), Reporting.Controls.update_result_table);
    }
  }

  Reporting.Controls.observe_click("query-icon-save-as", Reporting.Controls.toggle_save_as_form);
  Reporting.Controls.observe_click("query-icon-save-as-cancel", Reporting.Controls.toggle_save_as_form);
  $('save_as_form').hide();

  // When saving a new query, the success-response is the new saved query's url -> redirect to that
  Reporting.Controls.attach_settings_callback($("query-icon-save-button"), function (response) {
    Ajax.activeRequestCount = Ajax.activeRequestCount + 1; // HACK: Prevent Loading spinner from disappearing
    document.location = response.responseText;
  });
  // When saving an update of an exisiting query or apply filters, we replace the table on success
  Reporting.Controls.attach_settings_callback($("query-icon-apply-button"), Reporting.Controls.update_result_table);
  Reporting.Controls.observe_click($('query-link-clear'), Reporting.Controls.clear_query);
});


