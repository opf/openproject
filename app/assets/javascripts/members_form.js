jQuery(document).ready(function($) {

  $("#members_add_form").on("submit", function () {
    var error = $('.errorExplanation');
    if (error) {
      error.remove();
    }
  });
});