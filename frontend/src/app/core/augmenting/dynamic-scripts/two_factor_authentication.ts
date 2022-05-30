import QrCreator from 'qr-creator';

jQuery(($) => {
  $('#submit_otp').submit(() => {
    $('.ajax_form').find('input, radio').attr('disabled', 'disabled');
  });

  $('#toggle_resend_form').click(() => {
    $('#resend_otp_container').toggle();
    return false;
  });

  $('.qr-code-element').each(function () {
    QrCreator.render({
      text: this.dataset.value as string,
      radius: 0,
      ecLevel: 'H',
      fill: '#222222',
      background: '#FFFFFF',
      size: 250,
    }, this);
  });

  $('.ajax_form').submit(function () {
    $('#submit_otp').find('input').attr('disabled', 'disabled');
    const form = $(this);
    const submit_button = form.find('input[type=submit]');
    $.ajax({
      url: form.attr('action'),
      type: 'post',
      data: form.serialize(),
      beforeSend() {
        submit_button.attr('disabled', 'disabled');
        submit_button.toggleClass('submitting');
        $('.flash.notice').toggle();
      },
      complete(response) {
        submit_button.removeAttr('disabled');
        $('#submit_otp').find('input').removeAttr('disabled');
        $('.flash.notice a').html(response.responseText);
        $('form#resend_otp, #toggle_resend_form, .flash.notice').toggle();
        submit_button.toggleClass('submitting');
      },
    });
    return false;
  });

  $('#print_2fa_backup_codes').click(() => {
    window.print();
  });

  if ($('#download_2fa_backup_codes').length) {
    let text = '';
    $('.two-factor-authentication--backup-codes li').each(function () {
      text += `${this.textContent}\n`;
    });
    const element = $('#download_2fa_backup_codes');
    element.attr('href', `data:text/plain;charset=utf-8,${encodeURIComponent(text)}`);
    element.attr('download', 'backup-codes.txt');
  }
});
