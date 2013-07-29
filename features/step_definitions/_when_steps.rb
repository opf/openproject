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

When /^I fill in the ID of "([^"]*)" with (\d+) hash for "([^"]*)"$/ do |issue_name, number_hash_keys, container|
  issue = Issue.find_by_subject(issue_name)
  text = "#{('#' * number_hash_keys.to_i)}#{issue.id}"

  step %Q{I fill in "#{text}" for "#{container}"}
end

When /^I follow the issue link with (\d+) hash for "([^"]*)"$/ do |hash_count, issue_name|
  issue = Issue.find_by_subject(issue_name)

  text = ""
  if hash_count.to_i > 1
    text = issue.to_s
  elsif hash_count.to_i == 1
    text = "##{issue.id}"
  end

  step %Q{I follow "#{text}"}
end
