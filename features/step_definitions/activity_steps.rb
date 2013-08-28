#encoding: utf-8

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

When(/^I activate activity filter "(.*?)"/) do |activity_type|
  id = "show_#{activity_type.parameterize.underscore.pluralize.to_sym}"

  all(:xpath, "//input[@id='#{id}']").each do |checkbox|
    checkbox.set(true)
  end
end
