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

Then /^the breadcrumb should contain "(.+)"$/ do |string|
  container = ChiliProject::VERSION::MAJOR < 2 ?  "p.breadcrumb a" : "#breadcrumb a"

  steps %Q{ Then I should see "#{string}" within "#{container}" }
end


