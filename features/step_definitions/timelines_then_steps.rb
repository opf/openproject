#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Then(/^I should see a modal window with selector "(.*?)"$/) do |selector|
  page.should have_selector(selector)
  dialog = find(selector)

  dialog['class'].include?('ui-dialog-content').should be_truthy
end

Then(/^I should see the column "(.*?)" immediately before the column "(.*?)" in the timelines table$/) do |content1, content2|
  steps %{
    Then I should see the column "#{content1}" immediately before the column "#{content2}" in ".tl-main-table"
  }
end

Then(/^I should see the column "(.*?)" before the column "(.*?)" in the timelines table$/) do |content1, content2|
  steps %{
    Then I should see the column "#{content1}" before the column "#{content2}" in ".tl-main-table"
  }
end

Then(/^I should see the column "(.*?)" before the column "(.*?)" in "(.*?)"$/) do |content1, content2, table|
  # Check that the things really exist and wait until the exist
  steps %{
    Then I should see "#{content1}" within "#{table}"
    Then I should see "#{content2}" within "#{table}"
  }

  elements = find_lowest_containing_element content2, table
  elements[-1].should have_xpath("preceding::th/descendant-or-self::*[contains(text(),'#{content1}')]")
end

Then(/^I should see the column "(.*?)" immediately before the column "(.*?)" in "(.*?)"$/) do |content1, content2, table|
  # Check that the things really exist and wait until the exist
  steps %{
    Then I should see "#{content1}" within "#{table}"
    Then I should see "#{content2}" within "#{table}"
  }

  elements = find_lowest_containing_element content1, table
  following = elements[0].first :xpath, 'following::th'
  following.text.should == content2
end

Then(/^I should see a modal window$/) do
  steps 'Then I should see a modal window with selector "#modalDiv.ui-dialog-content"'
end

Then(/^I should not see a modal window$/) do
  page.should_not have_selector('#modalDiv.ui-dialog-content')
end

Then(/^(.*) in the modal$/) do |step|
  step(step + ' in the iframe "modalIframe"')
end

Then(/^I should (not )?see the work package "(.*?)" in the timeline$/) do |negate, work_package_name|
  steps %{
    Then I should #{negate}see "#{work_package_name}" within ".timeline .tl-left-main"
  }
end

Then(/^I should see "(.*?)" in the row of the work package "(.*?)"$/) do |content, wp_name|
  elements = find_lowest_containing_element wp_name, '.tl-main-table'
  elements[-1].should have_xpath("ancestor::tr/descendant-or-self::*[contains(text(), '#{content}')]")
end

Then(/^I should not see "(.*?)" in the row of the work package "(.*?)"$/) do |content, wp_name|
  elements = find_lowest_containing_element wp_name, '.tl-main-table'
  elements[-1].should_not have_xpath("ancestor::tr/descendant-or-self::*[text()='#{content}']")
end

Then(/^the project "(.*?)" should have an indent of (\d+)$/) do |project_name, indent|
  find(".tl-indent-#{indent}", text: project_name).should_not be_nil
end

Then(/^the project "(.*?)" should follow after "(.*?)"$/) do |project_name_one, project_name_two|
  # Check that the things really exist and wait until the exist
  steps %{
    Then I should see "#{project_name_one}" within ".tl-left-main"
    Then I should see "#{project_name_two}" within ".tl-left-main"
  }

  elements = find_lowest_containing_element project_name_one, '.tl-word-ellipsis'
  elements[-1].should have_xpath("preceding::span[contains(@class,'tl-word-ellipsis')]/descendant-or-self::*[text()='#{project_name_two}']")
end

Then(/^I should see the project "(.*?)"$/) do |project_name|
  steps %{
    Then I should see "#{project_name}" within ".tl-left-main"
  }
end

Then(/^I should not see the project "(.*?)"$/) do |project_name|
  steps %{
    Then I should not see "#{project_name}" within ".tl-left-main"
  }
end

Then(/^the first table column should not take more than 25% of the space$/) do
  result = page.evaluate_script("jQuery('.tl-left-main th').width() < (jQuery('body').width() * 0.25 + 22)")
  result.should be_truthy
end

Then(/^the "([^"]*)" row should (not )?be marked as default$/) do |title, negation|
  should_be_visible = !negation

  table_row = find_field(title).find(:xpath, './ancestor::tr')

  # The first column contains the Default value
  # TODO: This should not be a magic constant but derived from the actual table
  # header.
  if should_be_visible
    table_row.should have_css('td:nth-child(1) i.icon-checkmark')
  else
    table_row.should_not have_css('td:nth-child(1) i.icon-checkmark')
  end
end

Then(/^I should see that "([^"]*)" is( not)? a milestone and( not)? shown in aggregation$/) do |name, not_milestone, not_in_aggregation|
  row = page.find(:css, '.timelines-pet-name', text: Regexp.new("^#{name}$")).find(:xpath, './ancestor::tr')

  nodes = row.all(:css, '.timelines-pet-is_milestone i.icon-checkmark')
  if not_milestone
    nodes.should be_empty
  else
    nodes.should_not be_empty
  end

  nodes = row.all(:css, '.timelines-pet-in_aggregation i.icon-checkmark')
  if not_in_aggregation
    nodes.should be_empty
  else
    nodes.should_not be_empty
  end
end

Then(/^the "([^"]*)" row should (not )?be marked as allowing associations$/) do |title, negation|
  should_be_visible = !negation

  table_row = page
              .all(:css, 'table.generic-table tbody tr td', text: title)
              .first
              .find(:xpath, './ancestor::tr')
  nodes = table_row.all(:css, '.timelines-pt-allows_association i.icon-checkmark')
  if should_be_visible
    nodes.should_not be_empty
  else
    nodes.should be_empty
  end
end

Then(/^I should see that "([^"]*)" is a color$/) do |name|
  cell = page.all(:css, '.timelines-color-name', text: name)
  cell.should_not be_empty
end

Then(/^I should not see the "([^"]*)" color$/) do |name|
  cell = page.all(:css, '.timelines-color-name', text: name)
  cell.should be_empty
end

Then(/^"([^"]*)" should be the first element in the list$/) do |name|
  should have_selector('table.generic-table tbody tr td', text: Regexp.new("^#{name}$"))
end

Then(/^"([^"]*)" should be the last element in the list$/) do |name|
  has_css?('table.generic-table tbody tr td', text: Regexp.new("^#{name}$"))
end

Then(/^I should see an? (notice|warning|error) flash stating "([^"]*)"$/) do |class_name, message|
  page.all(:css, ".flash.#{class_name}, .flash.#{class_name} *", text: message).should_not be_empty
end

Then(/^I should see a planning element named "([^"]*)"$/) do |name|
  cells = page.all(:css, 'table td.timelines-pe-name *', text: name)
  cells.should_not be_empty
end

Then(/^I should( not)? see "([^"]*)" below "([^"]*)"$/) do |negation, text, heading|
  cells = page.all(:css, 'h1, h2, h3, h4, h5, h6', text: heading)
  cells.should_not be_empty

  container = cells.first.find(:xpath, "./ancestor::*[@class='container']")

  if negation
    container.should be_has_no_content(text)
  else
    container.should be_has_content(text)
  end
end

Then(/^I should not be able to add new project associations$/) do
  link = page.all(:css, 'a.timelines-new-project-associations')
  link.should be_empty
end

Then(/^I should (not )?see a planning element link for "([^"]*)"$/) do |negate, planning_element_subject|
  planning_element = PlanningElement.find_by(subject: planning_element_subject)
  text = "*#{planning_element.id}"

  step %{I should #{negate}see "#{text}"}
end

Then(/^I should (not )?see the timeline "([^"]*)"$/) do |negate, timeline_name|
  selector = 'div.timeline div.tl-left-main'
  timeline = Timeline.find_by(name: timeline_name)

  if (negate && page.has_css?(selector)) || !negate
    timeline.project.work_packages.each do |work_package|
      step %{I should #{negate}see "#{work_package.subject}" within "#{selector}"}
    end
  end
end
