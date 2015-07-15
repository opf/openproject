jQuery(function($) {
    if($('#new_password').length){
      showTooltips({
        element            : '.form--field-container input[name^="new"]',
      });

      $('#new_password_confirmation, #new_password').keyup(function() {
        var password_present = $('#password').val().length > 0;
        var button = $('input[name="commit"]');
        var new_pass = $('#new_password').val();
        var new_pass_confirm = $('#new_password_confirmation').val();
        var new_passwords_matches = new_pass === new_pass_confirm;
        var new_passwords_present = (new_pass.length > 0) && (new_pass_confirm.length > 0);

        if  (password_present && new_passwords_matches && new_passwords_present) {
          button.removeAttr('disabled');
        } else {
          button.attr('disabled','disabled');
        }
      });
    }
});
