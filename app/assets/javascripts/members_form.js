jQuery(document).ready(function($) {
  $("#tab-content-members").submit('#members_add_form', function () {
    var error = $('.errorExplanation, .flash');
    if (error) {
      error.remove();
    }
  });
});
