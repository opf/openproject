# encoding: utf-8

Then /^I should see an issue link for "([^"]*)" within "([^"]*)"$/ do |issue_name, container|
  issue = Issue.find_by_subject(issue_name)
  text = "##{issue.id}"

  step %Q{I should see "#{text}" within "#{container}"}
end

Then /^I should see a quickinfo link for "([^"]*)" within "([^"]*)"$/ do |issue_name, container|
  issue = Issue.find_by_subject(issue_name)

  text = "##{issue.id} #{issue.status}: #{issue.subject} #{issue.start_date.to_s} – #{issue.due_date.to_s} (#{issue.assigned_to.to_s})"
  step %Q{I should see "#{text}" within "#{container}"}
end

Then /^I should see a quickinfo link with description for "([^"]*)" within "([^"]*)"$/ do |issue_name, container|
    issue = Issue.find_by_subject(issue_name)

    step %Q{I should see a quickinfo link for "#{issue_name}" within "#{container}"}
    step %Q{I should see "#{issue.description}" within "#{container}"}
end
