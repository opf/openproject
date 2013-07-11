
(function() {
  function on_set_random_password_change(){
    var disabled = jQuery('#set_random_password').is(':checked');
    jQuery('#user_password')[0].disabled = disabled;
    jQuery('#user_password_confirmation')[0].disabled = disabled;
    jQuery('#user_password').val('');
    jQuery('#user_password_confirmation').val('');
  }

  function on_auth_source_change() {
    if (this.value === '') {
      jQuery('#password_fields').show();
    } else {
      jQuery('#password_fields').hide();
    }
  }

  jQuery(function init(){
    jQuery('#set_random_password').change(on_set_random_password_change);
    jQuery('#user_auth_source_id').change(on_auth_source_change);
  });
})();
