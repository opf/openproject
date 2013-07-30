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

jQuery(document).ready(function($) {
  $("#tab-content-members").submit('#members_add_form', function () {
    var error = $('.errorExplanation, .flash');
    if (error) {
      error.remove();
    }
  });
});
