//-- copyright
// OpenProject is a project management system.
//
// Copyright (C) 2012-2013 the OpenProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

$(document).observe('dom:loaded', function() {
  // If there is a flash message, give focus
  // necessary for screen readers
  var flash_focus = $$('div.flash a').first();
  if (flash_focus  != undefined) {
    flash_focus.focus();
  }
});
