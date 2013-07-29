
(function() {
  // When 'assign random password' field is enabled,
  // disable and clear password fields and disable and check the
  // 'force password reset' field
  function on_assign_random_password_change(){
    var checked = jQuery('#user_assign_random_password').is(':checked');
    jQuery('#user_password').prop('disabled', checked);
    jQuery('#user_password_confirmation').prop('disabled', checked);
    jQuery('#user_password').val('');
    jQuery('#user_password_confirmation').val('');
    jQuery('#user_force_password_change').prop('checked', checked)
                                         .prop('disabled', checked);
  }

  // Hide password fields when non-internal authentication source is selected
  function on_auth_source_change() {
    if (this.value === '') {
      jQuery('#password_fields').show();
    } else {
      jQuery('#password_fields').hide();
    }
  }

  jQuery(function init(){
    jQuery('#user_assign_random_password').change(on_assign_random_password_change);
    jQuery('#user_auth_source_id').change(on_auth_source_change);
  });
})();
