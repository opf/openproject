# encoding: utf-8

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


Then /^I should see an issue link for "([^"]*)"$/ do |issue_name|
  issue = Issue.find_by_subject(issue_name)
  text = "##{issue.id}"

  step %Q{I should see "#{text}"}
end

Then /^I should see a quickinfo link for "([^"]*)"$/ do |issue_name|
  issue = Issue.find_by_subject(issue_name)

  text = "#{issue.to_s} #{issue.start_date.to_s} – #{issue.due_date.to_s} (#{issue.assigned_to.to_s})"
  step %Q{I should see "#{text}"}
end

Then /^I should see a quickinfo link with description for "([^"]*)"$/ do |issue_name|
    issue = Issue.find_by_subject(issue_name)

    step %Q{I should see a quickinfo link for "#{issue_name}"}
    step %Q{I should see "#{issue.description}"}
end
