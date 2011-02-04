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
      clickToEditText: translations.clickToEdit
    });
  },

  toggle_delete_form: function () {
    var offset = $('query-icon-delete').positionedOffset().left;
    $('delete_form').setStyle("left: " + offset + "px").toggle();
    return false;
  },

  toggle_save_as_form: function () {
    var offset = $('query-icon-save-as').positionedOffset().left;
    $('save_as_form').setStyle("left: " + offset + "px").toggle();
    return false;
  },

  send_settings_data: function (targetUrl, callback) {
    selectAllOptions('group_by_rows');
    selectAllOptions('group_by_columns');
    Ajax.Request(
      targetUrl,
      { asynchronous: true,
        evalScripts: true,
        postBody: Form.serialize('query_form') + '&' + Form.serialize('query_save_as_form'),
        onSuccess: callback });
    return false;
  },

  attach_settings_callback: function (element, callback) {
    element.observe("click", function () {
      Reporting.Controls.send_settings_data(this.getAttribute("data-target"), callback);
      return false;
    });
  }
};

Reporting.onload(function () {
  if ($('query_saved_name').getAttribute("data-update-url") !== null) {
    Reporting.Controls.query_name_editor('query_saved_name');
  }
  $("query-icon-delete").observe("click", Reporting.Controls.toggle_delete_form);
  $("query-icon-save-as").observe("click", Reporting.Controls.toggle_save_as_form);
  $("query-icon-save-as-cancel").observe("click", Reporting.Controls.toggle_save_as_form);
  $('save_as_form').hide();
  $('delete_form').hide();

  // When saving a new query, the success-response is the new saved query's url -> redirect to that
  Reporting.Controls.attach_settings_callback($("query-icon-save-button"), function (response) {
    document.location = response.responseText;
  });
  // When saving an update of an exisiting query or just applying filters, we don't do anything on sucess
  Reporting.Controls.attach_settings_callback($("query-breadcrumb-save"), function (response) {});
  Reporting.Controls.attach_settings_callback($("query-icon-apply-button"), function (response) {});
});


