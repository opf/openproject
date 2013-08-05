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

Then /^I should see the planning element edit modal$/ do
 steps 'Then I should see a modal window with selector "#planningElementDialog"'
end
Then /^I should see a modal window with selector "(.*?)"$/ do |selector|
  page.should have_selector(selector)
  dialog = find(selector)

  dialog["class"].include?("ui-dialog-content").should be_true
end
Then /^I should see a modal window$/ do
  steps 'Then I should see a modal window with selector ".ui-dialog-content"'
end
Then(/^I should not see the planning element "(.*?)"$/) do |planning_element_name|
  steps %Q{
    Then I should not see "#{planning_element_name}" within ".tl-left-main"
  }
end
Then(/^the project "(.*?)" should have an indent of (\d+)$/) do |project_name, indent|
  find(".tl-indent-#{indent}", :text => project_name).should_not be_nil
end
Then(/^the project "(.*?)" should follow after "(.*?)"$/) do |project_name_one, project_name_two|
  #Check that the things really exist and wait until the exist
  steps %Q{
    Then I should see "#{project_name_one}" within ".tl-left-main"
    Then I should see "#{project_name_two}" within ".tl-left-main"
  }

  elements = find_lowest_containing_element project_name_one, ".tl-word-ellipsis"
  elements[-1].should have_xpath("preceding::span[@class='tl-word-ellipsis']/descendant-or-self::*[text()='#{project_name_two}']")
end
Then(/^I should see the planning element "(.*?)"$/) do |planning_element_name|
  steps %Q{
    Then I should see "#{planning_element_name}" within ".tl-left-main"
  }
end
Then(/^I should see the project "(.*?)"$/) do |project_name|
  steps %Q{
    Then I should see "#{project_name}" within ".tl-left-main"
  }
end
Then(/^I should not see the project "(.*?)"$/) do |project_name|
  steps %Q{
    Then I should not see "#{project_name}" within ".tl-left-main"
  }
end
Then /^the first table column should not take more than 25% of the space$/ do
  result = page.evaluate_script("jQuery('.tl-left-main th').width() < (jQuery('body').width() * 0.25 + 22)")
  result.should be_true
end

Then /^the "([^"]*)" row should (not )?be marked as default$/ do |title, negation|
  should_be_visible = !negation

  table_row = find_field(title).find(:xpath, "./ancestor::tr")

  # The first column contains the Default value
  # TODO: This should not be a magic constant but derived from the actual table
  # header.
  if should_be_visible
    table_row.should have_css('td:nth-child(1) img[alt=checked]')
  else
    table_row.should_not have_css('td:nth-child(1) img[alt=checked]')
  end
end

Then /^I should see that "([^"]*)" is( not)? a milestone and( not)? shown in aggregation$/ do |name, not_milestone, not_in_aggregation|
  row = page.find(:css, ".timelines-pet-name", :text => Regexp.new("^#{name}$")).find(:xpath, './ancestor::tr')

  nodes = row.all(:css, '.timelines-pet-is_milestone img[alt=checked]')
  if not_milestone
    nodes.should be_empty
  else
    nodes.should_not be_empty
  end

  nodes = row.all(:css, '.timelines-pet-in_aggregation img[alt=checked]')
  if not_in_aggregation
    nodes.should be_empty
  else
    nodes.should_not be_empty
  end
end

Then /^the "([^"]*)" row should (not )?be marked as allowing associations$/ do |title, negation|
  should_be_visible = !negation

  table_row = page.all(:css, "table.list tbody tr td", :text => title).first.find(:xpath, "./ancestor::tr")
  nodes = table_row.all(:css, '.timelines-pt-allows_association img[alt=checked]')
  if should_be_visible
    nodes.should_not be_empty
  else
    nodes.should be_empty
  end
end

Then /^I should see that "([^"]*)" is a color$/ do |name|
  cell = page.all(:css, ".timelines-color-name", :text => name)
  cell.should_not be_empty
end

Then /^I should not see the "([^"]*)" color$/ do |name|
  cell = page.all(:css, ".timelines-color-name", :text => name)
  cell.should be_empty
end

Then /^"([^"]*)" should be the first element in the list$/ do |name|
  should have_selector("table.list tbody tr td", :text => Regexp.new("^#{name}$"))
end

Then /^"([^"]*)" should be the last element in the list$/ do |name|
  has_css?("table.list tbody tr td", :text => Regexp.new("^#{name}$"))
end

Then /^I should see an? (notice|warning|error) flash stating "([^"]*)"$/ do |class_name, message|
  page.all(:css, ".flash.#{class_name}, .flash.#{class_name} *", :text => message).should_not be_empty
end

Then /^I should see a planning element named "([^"]*)"$/ do |name|
  cells = page.all(:css, "table td.timelines-pe-name *", :text => name)
  cells.should_not be_empty
end

Then /^I should( not)? see "([^"]*)" below "([^"]*)"$/ do |negation, text, heading|
  cells = page.all(:css, "h1, h2, h3, h4, h5, h6", :text => heading)
  cells.should_not be_empty

  container = cells.first.find(:xpath, "./ancestor::*[@class='container']")

  if negation
    container.should be_has_no_content(text)
  else
    container.should be_has_content(text)
  end
end

Then /^I should not be able to add new project associations$/ do
  link = page.all(:css, "a.timelines-new-project-associations")
  link.should be_empty
end

Then /^I should (not )?see a planning element link for "([^"]*)"$/ do |negate, planning_element_subject|
  planning_element = PlanningElement.find_by_subject(planning_element_subject)
  text = "*#{planning_element.id}"

  step %Q{I should #{negate}see "#{text}"}
end

Then /^I should (not )?see a planning element quickinfo link for "([^"]*)"$/ do |negate, planning_element_subject|
  planning_element = PlanningElement.find_by_subject(planning_element_subject)


  text = "*#{planning_element.id} #{planning_element.planning_element_status.nil? ? "" : planning_element.planning_element_status.name + ":"} #{planning_element.subject} #{planning_element.start_date.to_s} – #{planning_element.due_date.to_s} (#{planning_element.responsible.to_s})"
  step %Q{I should #{negate}see "#{text}"}
end

Then /^I should (not )?see a planning element quickinfo link with description for "([^"]*)"$/ do |negate, planning_element_subject|
  planning_element = PlanningElement.find_by_subject(planning_element_subject)

  step %Q{I should #{negate}see a planning element quickinfo link for "#{planning_element_subject}"}
  step %Q{I should #{negate}see "#{planning_element.description}"}
end

Then /^I should (not )?see the timeline "([^"]*)"$/ do |negate, timeline_name|
  selector = "div.timeline div.tl-left-main"
  timeline = Timeline.find_by_name(timeline_name)

  if (negate && page.has_css?(selector)) || !negate
    timeline.project.planning_elements.each do |planning_element|
      step %Q{I should #{negate}see "#{planning_element.subject}" within "#{selector}"}
    end
  end
end
