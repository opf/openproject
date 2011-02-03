/*jslint white: false, nomen: true, devel: true, on: true, debug: false, evil: true, onevar: false, browser: true, white: false, indent: 2 */
/*global window, $, $$, Reporting, Effect, Ajax, Element */

Reporting.Controls = {
  query_name_editor: function (target_id) {
    var target = $(target_id);
    var isPublic = target.getAttribute("data-is_public") === "true";
    var updateUrl = target.getAttribute("data-update_url");
    var translations = target.getAttribute("data-translations");
    if (translations.isJSON()) {
      translations = translations.evalJSON(true);
    } else {
      translations = {};
    }

    Ajax.InPlaceEditor(target_id, updateUrl, {
      callback: function (form, value) {
        return  'query_is_public=' + (form.query_is_public.checked === true) + '&query_name=' + encodeURIComponent(value);
      },
      okControl: 'button',
      cancelControl: 'button',
      externalControl: 'query-name-edit-button',
      okText: translations.rename === undefined ? 'ok' : translations.rename,
      cancelText: translations.cancel === undefined ? 'cancel' : translations.cancel,
      savingText: translations.saving === undefined ? 'Saving...' : translations.saving,
      loadingText: translations.loading === undefined ? 'Loading...' : translations.loading,
      clickToEditText: translations.clickToEdit === undefined ? 'Click to edit' : translations.clickToEdit,
      onFormCustomization: function (ipe, ipeForm) {
        var label;
        var checkbox;
        var chk_id = 'rename_query_is_public';

        checkbox = document.createElement('input');
        checkbox.value = 1;
        checkbox.type = 'checkbox';
        checkbox.id = chk_id;
        checkbox.name = 'query_is_public';
        checkbox.checked = isPublic;

        label = document.createElement('label');
        label.id = 'in_place_save_is_public_question';
        label.htmlFor = chk_id;
        label.appendChild(document.createTextNode(translations.isPublic === undefined ? 'public?' : translations.isPublic));

        ipeForm.insert(label);
        ipeForm.insert(checkbox);
      }
    });
  },

  toggle_delete_form: function () {
    var offset = $('query-icon-delete').positionedOffset().left;
    $('delete_form').setStyle("left: " + offset + "px").toggle();
  }
};

Reporting.onload(function () {
  Reporting.Controls.query_name_editor('query_saved_name');
  $("query-icon-delete").observe("click", Reporting.Controls.toggle_delete_form);
});


