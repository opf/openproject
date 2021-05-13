/**
 * Move from legacy app/assets/javascripts/application.js.erb
 *
 * This should not be loaded globally and ideally refactored into components
 */
export function listenToSettingChanges() {
  jQuery('#settings_session_ttl_enabled').on('change', function () {
    jQuery('#settings_session_ttl_container').toggle(jQuery(this).is(':checked'));
  }).trigger('change');


  /** Sync SCM vendor select when enabled SCMs are changed */
  jQuery('[name="settings[enabled_scm][]"]').change(function (this:HTMLInputElement) {
    var wasDisabled = !this.checked,
      vendor = this.value,
      select = jQuery('#settings_repositories_automatic_managed_vendor'),
      option = select.find('option[value="' + vendor + '"]');

    // Skip non-manageable SCMs
    if (option.length === 0) {
      return;
    }

    option.prop('disabled', wasDisabled);
    if (wasDisabled && option.prop('selected')) {
      select.val('');
    }
  });

  /* Javascript for Settings::TextSettingCell */
  const langSelectSwitchData = function (select:any) {
    const self = jQuery(select);
    const id:string = self.attr("id") || '';
    const settingName = id.replace('lang-for-', '');
    const newLang = self.val();
    const textArea = jQuery(`#settings-${settingName}`);
    const editor = textArea.siblings('ckeditor-augmented-textarea').data('editor');

    return { id: id, settingName: settingName, newLang: newLang, textArea: textArea, editor: editor };
  };

  // Upon focusing:
  //   * store the current value of the editor in the hidden field for that lang.
  // Upon change:
  //   * get the current value from the hidden field for that lang and set the editor text to that value.
  //   * Set the name of the textarea to reflect the current lang so that the value stored in the hidden field
  //     is overwritten.
  jQuery(".lang-select-switch")
    .focus(function () {
      const data = langSelectSwitchData(this);

      jQuery(`#${data.id}-${data.newLang}`).val(data.editor.getData());
    })
    .change(function () {
      const data = langSelectSwitchData(this);

      const storedValue = jQuery(`#${data.id}-${data.newLang}`).val();

      data.editor.setData(storedValue);
      data.textArea.attr('name', `settings[${data.settingName}][${data.newLang}]`);
    });
  /* end Javascript for Settings::TextSettingCell */

  jQuery('.admin-settings--form').submit(function () {
    /* Update consent time if consent required */
    if (jQuery('#settings_consent_required').is(':checked') && jQuery('#toggle_consent_time').is(':checked')) {
      jQuery('#settings_consent_time')
        .val(new Date().toISOString())
        .prop('disabled', false);
    }

    return true;
  });

  /** Toggle notification settings fields */
  jQuery("#email_delivery_method_switch").on("change", function () {
    const delivery_method = jQuery(this).val();
    jQuery(".email_delivery_method_settings").hide();
    jQuery("#email_delivery_method_" + delivery_method).show();
  }).trigger("change");

  jQuery('#settings_smtp_authentication').on('change', function () {
    var isNone = jQuery(this).val() === 'none';
    jQuery('#settings_smtp_user_name,#settings_smtp_password')
      .closest('.form--field')
      .toggle(!isNone);
  });

  /** Toggle repository checkout fieldsets required when option is disabled */
  jQuery('.settings-repositories--checkout-toggle').change(function (this:HTMLInputElement) {
    var wasChecked = this.checked,
      fieldset = jQuery(this).closest('fieldset');

    fieldset
      .find('input,select')
      .filter(':not([type=checkbox])')
      .filter(':not([type=hidden])')
      .removeAttr('required') // Rails 4.0 still seems to use attribute
      .prop('required', wasChecked);
  });

  /** Toggle highlighted attributes visibility depending on if the highlighting mode 'inline' was selected*/
  jQuery('.settings--highlighting-mode select').change(function () {
    var highlightingMode = jQuery(this).val();
    jQuery(".settings--highlighted-attributes").toggle(highlightingMode === "inline");
  });

  /** Initialize hightlighted attributes checkboxes. If none is selected, it means we want them all. So let's
   * show them all as selected.
   * On submitting the form, we remove all checkboxes before sending to communicate, we actually want all and not
   * only the selected.*/
  if (jQuery(".settings--highlighted-attributes input[type='checkbox']:checked").length === 0) {
    jQuery(".settings--highlighted-attributes input[type='checkbox']").prop("checked", true);
  }
  jQuery('#tab-content-work_packages form').submit(function () {
    var availableAttributes = jQuery(".settings--highlighted-attributes input[type='checkbox']");
    var selectedAttributes = jQuery(".settings--highlighted-attributes input[type='checkbox']:checked");
    if (selectedAttributes.length === availableAttributes.length) {
      availableAttributes.prop("checked", false);
    }
  });
}
