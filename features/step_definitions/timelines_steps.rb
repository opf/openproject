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

# Merge those two once Issue == PlanningElement == WorkPackage
Then(/^I should (not )?see the planning element "(.*?)" in the timeline$/) do |negate, planning_element_name|
  steps %Q{
    Then I should #{negate}see "#{planning_element_name}" within ".timeline .tl-left-main"
  }
end

Then(/^I should (not )?see the issue "(.*?)" in the timeline$/) do |negate, issue_name|
  steps %Q{
    Then I should #{negate}see "#{issue_name}" within ".timeline .tl-left-main"
  }
end
