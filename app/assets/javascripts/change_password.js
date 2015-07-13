jQuery(function($) {
    if($('#new_password').length){
      $('#new_password_confirmation, #new_password, #password').keyup(function() {
        var passwordPresent = $('#password').val().length > 0;
        var button = $('input[name="commit"]');
        var newPass = $('#new_password').val();
        var newPassConfirm = $('#new_password_confirmation').val();
        var newPasswordsMatches = newPass === newPassConfirm;
        var newPasswordsPresent = (newPass.length > 0) && (newPassConfirm.length > 0);

        if  (passwordPresent && newPasswordsMatches && newPasswordsPresent) {
          button.removeAttr('disabled');
        } else {
          button.attr('disabled','disabled');
        }
      });
    }
});
