jQuery(function($) {
  function toggleContentTypeForm(content_type, edit) {
    jQuery('.edit-' + content_type).toggle(edit);
    jQuery('.show-' + content_type).toggle(!edit);

    jQuery('.button--edit-agenda').toggleClass('-active', edit);
    jQuery('.button--edit-agenda').attr('disabled', edit);
  }

  $('.button--edit-agenda').click(function() {
    var content_type = $(this).data('contentType');
    toggleContentTypeForm(content_type, true);

    return false;
  });

  $('.button--cancel-agenda').click(function() {
    var content_type = $(this).data('contentType');
    toggleContentTypeForm(content_type, false);

    return false;
  });


  $('.meetings--checkbox-version-to').click(function() {
    var target = $(this).data('target');
    $(target).prop('checked', true);
  });
});