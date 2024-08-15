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
    const wasDisabled = !this.checked;
    const vendor = this.value;
    const select = jQuery('#settings_repositories_automatic_managed_vendor');
    const option = select.find(`option[value="${vendor}"]`);

    // Skip non-manageable SCMs
    if (option.length === 0) {
      return;
    }

    option.prop('disabled', wasDisabled);
    if (wasDisabled && option.prop('selected')) {
      select.val('');
    }
  });

  /* Javascript for Settings::TextSettingComponent */
  const langSelectSwitchData = function (select:any) {
    const self = jQuery(select);
    const id:string = self.attr('id') || '';
    const settingName = id.replace('lang-for-', '');
    const newLang = self.val() as string;
    const textArea = jQuery(`#settings-${settingName}`);
    /* eslint-disable-next-line @typescript-eslint/no-unsafe-assignment */
    const editor = textArea.siblings('opce-ckeditor-augmented-textarea').data('editor');

    return {
      id, settingName, newLang, textArea, editor,
    };
  };

  // Upon focusing:
  //   * store the current value of the editor in the hidden field for that lang.
  // Upon change:
  //   * get the current value from the hidden field for that lang and set the editor text to that value.
  //   * Set the name of the textarea to reflect the current lang so that the value stored in the hidden field
  //     is overwritten.
  jQuery('.lang-select-switch')
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
  /* end Javascript for Settings::TextSettingComponent */

  /** Toggle notification settings fields */
  jQuery('#email_delivery_method_switch').on('change', function () {
    const delivery_method = jQuery(this).val();
    jQuery('.email_delivery_method_settings').hide();
    jQuery(`#email_delivery_method_${delivery_method}`).show();
  }).trigger('change');

  jQuery('#settings_smtp_authentication').on('change', function () {
    const isNone = jQuery(this).val() === 'none';
    jQuery('#settings_smtp_user_name,#settings_smtp_password')
      .closest('.form--field')
      .toggle(!isNone);
  });

  /** Toggle repository checkout fieldsets required when option is disabled */
  jQuery('.settings-repositories--checkout-toggle').change(function (this:HTMLInputElement) {
    const wasChecked = this.checked;
    const fieldset = jQuery(this).closest('fieldset');

    fieldset
      .find('input,select')
      .filter(':not([type=checkbox])')
      .filter(':not([type=hidden])')
      .removeAttr('required') // Rails 4.0 still seems to use attribute
      .prop('required', wasChecked);
  });

  /** Toggle highlighted attributes visibility depending on if the highlighting mode 'inline' was selected */
  jQuery('.settings--highlighting-mode select').change(function () {
    const highlightingMode = jQuery(this).val();
    jQuery('.settings--highlighted-attributes').toggle(highlightingMode === 'inline');
  });

  jQuery('#tab-content-work_packages form').submit(() => {
    const availableAttributes = jQuery(".settings--highlighted-attributes input[type='checkbox']");
    const selectedAttributes = jQuery(".settings--highlighted-attributes input[type='checkbox']:checked");
    if (selectedAttributes.length === availableAttributes.length) {
      availableAttributes.prop('checked', false);
    }
  });
}
