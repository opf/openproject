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

When /^I select "(.+)" from the available widgets drop down$/ do |widget_name|
  steps %{When I select "#{widget_name}" from "block-select"}
end

Then /^"(.+)" should be disabled in the available widgets drop down$/ do |widget_name|
  option_name = MyProjectsOverviewsController::BLOCKS.detect{|k, v| I18n.t(v) == widget_name}.first

  steps %Q{Then the "block-select" drop-down should have the following options disabled:
            | #{option_name} |}
end


Then /^I should see the dropdown of available widgets$/ do
  page.has_select?('block-select', :options => ['Watched Issues', 'Issues assigned to me'])
end
Then(/^I should see the widget "([^"]*)"$/) do |arg|
  page.find("#widget_#{arg}").should_not be_nil
end