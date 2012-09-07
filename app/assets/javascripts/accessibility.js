$(document).observe('dom:loaded', function() {
  // If there is a flash message, give focus
  // necessary for screen readers
  var flash_focus = $$('div.flash a').first();
  if (flash_focus  != undefined) {
    flash_focus.focus();
  }
});
