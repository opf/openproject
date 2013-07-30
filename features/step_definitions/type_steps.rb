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

# change from symbol to constant once namespace is removed

InstanceFinder.register(:type, Proc.new { |name| Type.find_by_name(name) })

RouteMap.register(Type, "/types")

Then /^I should not see the "([^"]*)" type$/ do |name|
  page.all(:css, '.timelines-pet-name', :text => name).should be_empty
end
