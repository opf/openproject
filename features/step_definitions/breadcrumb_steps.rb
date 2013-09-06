#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Then /^the breadcrumbs should (not )?have the element "(.+)"$/ do |negation, string|
  # find all descendants of an element with id 'breadcrumb' that have a child text node equalling
  # string
  selector = have_xpath("//*[@id='breadcrumb']//*[text()='#{string}']")
  if negation == 'not '
    should_not selector
  else
    should selector
  end
end
