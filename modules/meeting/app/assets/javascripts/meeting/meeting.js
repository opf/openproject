jQuery(function($) {
  var formSubmitting = false;
  var editFormOpen = false;
  if (jQuery('#edit-meeting_agenda').is(':visible') || jQuery('#edit-meeting_minutes').is(':visible')) {
    editFormOpen = true;
  }

  $(window).on("beforeunload", function (e) {
    // When the form is not open or just submitted,
    // we can safely leave the page
    if(!editFormOpen || formSubmitting) {
      return undefined;
    } else {
      // Otherwise we throw a warning
      // For browser compatibility we need to set the event return value
      e.preventDefault();
      return e.returnValue = I18n.t('js.modals.form_submit.text');
    }
  });

  function toggleContentTypeForm(content_type, edit) {
    jQuery('.edit-' + content_type).toggle(edit);
    jQuery('.show-' + content_type).toggle(!edit);
    editFormOpen = edit;

    jQuery('.button--edit-agenda').toggleClass('-active', edit);
    jQuery('.button--edit-agenda').attr('disabled', edit);

    jQuery('.meeting_content ~ attachments').toggle(!edit);
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

  $('.button--save-agenda').click(function() {
    formSubmitting = true;
  });


  $('.meetings--checkbox-version-to').click(function() {
    var target = $(this).data('target');
    $(target).prop('checked', true);
  });
});
