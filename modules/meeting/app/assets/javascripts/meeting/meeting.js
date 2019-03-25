jQuery(function($) {
  var formSubmitting = false;
  function toggleContentTypeForm(content_type, edit) {
    jQuery('.edit-' + content_type).toggle(edit);
    jQuery('.show-' + content_type).toggle(!edit);

    jQuery('.button--edit-agenda').toggleClass('-active', edit);
    jQuery('.button--edit-agenda').attr('disabled', edit);
  }

  $('.button--edit-agenda').click(function() {
    var content_type = $(this).data('contentType');
    toggleContentTypeForm(content_type, true);


    $(window).on("beforeunload", function (e) {
      if (formSubmitting) {
        return undefined;
      }

      // For browser compatibility we need to set the event return value
      e.returnValue = '';
      return '';
    });

    return false;
  });

  $('.button--cancel-agenda').click(function() {
    var content_type = $(this).data('contentType');
    toggleContentTypeForm(content_type, false);

    $(window).off("beforeunload");

    return false;
  });

  $('.button--save-agenda').click(function() {
    formSubmitting = true;
  });


  $('.meetings--checkbox-version-to').click(function() {
    var target = $(this).data('target');
    $(target).prop('checked', true);
  });
});
