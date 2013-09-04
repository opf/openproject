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

Then /^"(.+)" should be disabled in the my project page available widgets drop down$/ do |widget_name|
  option_name = MyProjectsOverviewsController::BLOCKS.detect{|k, v| I18n.t(v) == widget_name}.first.dasherize

  steps %Q{Then the "block-select" drop-down should have the following options disabled:
            | #{option_name} |}
end
