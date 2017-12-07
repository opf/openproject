//= require two_factor_authentication/vendor/qrcode-min

jQuery(function ($) {
  $('#submit_otp').submit(function(){
    $('.ajax_form').find("input, radio").attr('disabled','disabled');
  });

  $('#toggle_resend_form').click(function(){
    $('#resend_otp_container').toggle();
    return false;
  });

  $('.qr-code-element').each(function() {
    var el = $(this);
    new QRCode(
      el[0],
      {
        text: el.data('value'),
        width: 220,
        height: 220
      }
    );
  });

  $('.ajax_form').submit(function(){
    $('#submit_otp').find("input").attr('disabled','disabled');
    var form = $(this),
        submit_button = form.find("input[type=submit]");
    $.ajax({ url: form.attr('action'),
             type: 'post',
             data: form.serialize(),
             beforeSend: function(){
               submit_button.attr('disabled','disabled');
               submit_button.toggleClass('submitting');
               $('.flash.notice').toggle();
             },
             complete: function(response){
               submit_button.removeAttr('disabled');
               $('#submit_otp').find("input").removeAttr('disabled');
               $('.flash.notice a').html(response.responseText);
               $('form#resend_otp, #toggle_resend_form, .flash.notice').toggle();
               submit_button.toggleClass('submitting');
             }
    });
    return false;
  });

  $('#print_2fa_backup_codes').click(function() {
    window.print();
  });

  if ($('#download_2fa_backup_codes').length) {
    var text = '';
    $('.two-factor-authentication--backup-codes li').each(function() { text += this.textContent + "\n"; });
    var element = $('#download_2fa_backup_codes');
    element.attr('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
    element.attr('download', 'backup-codes.txt');
  }
});
