#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

When (/^I click on the Planning Element with name "(.*?)"$/) do |planning_element_subject|
  first('a', text: planning_element_subject).click
end

When (/^I click on the Edit Link$/) do
  click_link('Update')
end

When (/^I click on the Save Link$/) do
  click_link('Save')
end

When (/^I hide empty projects for the timeline "([^"]*?)" of the project called "([^"]*?)"$/) do |timeline_name, project_name|
  steps %{
    When I go to the edit page of the timeline "#{timeline_name}" of the project called "#{project_name}"
  }

  page.should have_selector('#timeline_options_exclude_empty', visible: false)

  page.execute_script("jQuery('#timeline_options_exclude_empty').prop('checked', true)")
  page.execute_script("jQuery('#content form').submit()")
end

When (/^I make the planning element "([^"]*?)" vertical for the timeline "([^"]*?)" of the project called "([^"]*?)"$/) do |planning_element_subject, timeline_name, project_name|
  steps %{
    When I go to the edit page of the timeline "#{timeline_name}" of the project called "#{project_name}"
  }
  planning_element = PlanningElement.find_by_subject(planning_element_subject)

  page.should have_selector('#timeline_options_vertical_planning_elements', visible: false)

  page.execute_script("jQuery('#timeline_options_vertical_planning_elements').val('#{planning_element.id}')")
  page.execute_script("jQuery('#content form').submit()")
end

When(/^I filter for work packages with custom boolean field "(.*?)" set to "(.*?)"$/) do |field_name, value|
  steps %{
   When I edit the settings of the current timeline
 }

  custom_field = InstanceFinder.find(WorkPackageCustomField, field_name)

  page.execute_script("jQuery('#timeline_options_custom_fields_#{custom_field.id}').val('#{value}')")
  page.execute_script("jQuery('#content form').submit()")
end

When(/^I filter for work packages with custom list field "(.*?)" set to "(.*?)"$/) do |field_name, value|
  steps %{
   When I edit the settings of the current timeline
 }

  custom_field = InstanceFinder.find(WorkPackageCustomField, field_name)

  page.execute_script("jQuery('#timeline_options_custom_fields_#{custom_field.id}_').val('#{value}')")
  page.execute_script("jQuery('#content form').submit()")
end

When (/^I edit the settings of the current timeline$/) do
  timeline_name = @timeline_name
  project_name = @project.name
  steps %{
    When I go to the edit page of the timeline "#{timeline_name}" of the project called "#{project_name}"
  }
end

When (/^I set the first level grouping criteria to "(.*?)" for the timeline "(.*?)" of the project called "(.*?)"$/) do |grouping_project_name, timeline_name, project_name|
  steps %{
    When I go to the edit page of the timeline "#{timeline_name}" of the project called "#{project_name}"
  }
  grouping_project = Project.find_by_name(grouping_project_name)

  page.should have_selector('#timeline_options_grouping_one_enabled', visible: false)

  page.execute_script("jQuery('#timeline_options_grouping_one_enabled').prop('checked', true)")
  page.execute_script("jQuery('#timeline_options_grouping_one_selection').val('#{grouping_project.id}')")
  page.execute_script("jQuery('#content form').submit()")
end

When (/^I enable the hide other group option$/) do
  # it is not possible to use the label for the hide group other field
  # because of the " in the label
  steps %{
    When I edit the settings of the current timeline
    And I check "timeline_options_hide_other_group"
    And I click on "Save"
  }
end

When (/^I show only work packages which have the responsible "(.*?)"$/) do |responsible|
  steps %{
    When I edit the settings of the current timeline
  }

  responsible = User.find_by_login(responsible)
  page.execute_script(<<-JavaScript)
    jQuery('#timeline_options_planning_element_responsibles').val('#{responsible.id}')
    jQuery('#content form').submit()
  JavaScript
end

When (/^I show only work packages which have no responsible$/) do
  steps %{
    When I edit the settings of the current timeline
  }

  page.execute_script(<<-JavaScript)
    jQuery('#timeline_options_planning_element_responsibles').val('-1')
    jQuery('#content form').submit()
  JavaScript
end

When (/^I show only work packages which have the type "(.*?)"$/) do |type|
  steps %{
    When I edit the settings of the current timeline
  }

  type = Type.find_by_name(type)
  page.execute_script(<<-JavaScript)
    jQuery('#timeline_options_planning_element_types').val('#{type.id}')
    jQuery('#content form').submit()
  JavaScript
end

When (/^I show only projects which have responsible set to "(.*?)"$/) do |responsible|
  steps %{
    When I edit the settings of the current timeline
  }

  page.should have_selector('#timeline_options_project_responsibles', visible: false)

  responsible = User.find_by_login(responsible)
  page.execute_script("jQuery('#timeline_options_project_responsibles').val('#{responsible.id}')")
  page.execute_script("jQuery('#content form').submit()")
end

When (/^I show only projects which have a planning element which lies between "(.*?)" and "(.*?)" and has the type "(.*?)"$/) do |start_date, due_date, type|
  steps %{
    When I edit the settings of the current timeline
  }

  page.should have_selector('#timeline_options_planning_element_time_types', visible: false)

  type = Type.find_by_name(type)
  page.execute_script("jQuery('#timeline_options_planning_element_time_types').val('#{type.id}')")
  page.execute_script("jQuery('#timeline_options_planning_element_time_absolute').prop('checked', true)")
  page.execute_script("jQuery('#timeline_options_planning_element_time_absolute_one').val('#{start_date}')")
  page.execute_script("jQuery('#timeline_options_planning_element_time_absolute_two').val('#{due_date}')")
  page.execute_script("jQuery('#content form').submit()")
end

When (/^I set the second level grouping criteria to "(.*?)" for the timeline "(.*?)" of the project called "(.*?)"$/) do |project_type_name, timeline_name, project_name|
  steps %{
    When I go to the edit page of the timeline "#{timeline_name}" of the project called "#{project_name}"
  }
  project_type = ProjectType.find_by_name(project_type_name)

  check(I18n.t('timelines.filter.grouping_two'))
  fill_in(I18n.t('timelines.filter.grouping_two_phrase'), with: project_type.name)
  find('.select2-result-label', text: project_type.name).click

  click_button(I18n.t(:button_save))
end
When (/^I set the columns shown in the timeline to:$/) do |table|
  steps %{
    When I edit the settings of the current timeline
  }
  result = []
  table.raw.each do |_perm|
    perm = _perm.first
    unless perm.blank?
      result.push(perm)
    end
  end
  results = result.join(',')

  # we need to wait for our submit form to load ...
  page.should have_selector('#timeline_options_columns_', visible: false)

  page.execute_script("jQuery('#timeline_options_columns_').val('#{results}')")

  page.execute_script("jQuery('#content form').submit()")
end

When (/^I set the first level grouping criteria to:$/) do |table|
  steps %{
    When I edit the settings of the current timeline
  }
  result = []
  table.raw.each do |_perm|
    perm = _perm.first
    unless perm.blank?
      result.push(Project.find_by_name(perm).id)
    end
  end
  results = result.join(',')

  # we need to wait for our submit form to load ...
  page.should have_selector('#timeline_options_grouping_one_enabled', visible: false)

  page.execute_script("jQuery('#timeline_options_grouping_one_enabled').prop('checked', true)")
  page.execute_script("jQuery('#timeline_options_grouping_one_selection').val('#{results}')")

  page.execute_script("jQuery('#content form').submit()")
end

When (/^I set the sortation of the first level grouping criteria to explicit order$/) do
  steps %{
    When I edit the settings of the current timeline
  }

  page.should have_selector('#timeline_options_grouping_one_sort', visible: false)

  page.execute_script("jQuery('#timeline_options_grouping_one_sort').val('1')")
  page.execute_script("jQuery('#content form').submit()")
end

When (/^I click on the Restore Link$/) do
  page.execute_script("jQuery('.input-as-link').click()")
end

When (/^I wait (\d+) seconds?$/) do |seconds|
  sleep seconds.to_i
end

When (/^I set duedate to "([^"]*)"$/) do |value|
  fill_in 'planning_element_due_date', with: value
end

When (/^I wait for timeline to load table$/) do
  extend ::Angular::DSL unless singleton_class.included_modules.include?(::Angular::DSL)
  ng_wait

  page.should have_selector('.tl-left-main')
end

When (/^I move "([^"]*)" to the top$/) do |name|
  cell = find(:css, 'table.list td', text: Regexp.new("^#{name}$"))
  row = cell.find(:xpath, './ancestor::tr')
  link = row.find_link('Move to top')
  link.click
end

When (/^I move "([^"]*)" to the bottom$/) do |name|
  cell = find(:css, 'table.list td', text: Regexp.new("^#{name}$"))
  row = cell.find(:xpath, './ancestor::tr')
  link = row.find_link('Move to bottom')
  link.click
end

When (/^I move "([^"]*)" up by one$/) do |name|
  cell = find(:css, 'table.list td', text: Regexp.new("^#{name}$"))
  row = cell.find(:xpath, './ancestor::tr')
  link = row.find_link('Move up')
  link.click
end

When (/^I move "([^"]*)" down by one$/) do |name|
  cell = find(:css, 'table.list td', text: Regexp.new("^#{name}$"))
  row = cell.find(:xpath, './ancestor::tr')
  link = row.find_link('Move down')
  link.click
end

When (/^I fill in a wiki macro for timeline "([^"]*)" for "([^"]*)"$/) do |timeline_name, container|
  timeline = Timeline.find_by_name(timeline_name)

  text = "{{timeline(#{timeline.id})}}"
  step %{I fill in "#{text}" for "#{container}"}
end

When (/^(.*) for the color "([^"]*)"$/) do |step_name, color_name|
  color = PlanningElementTypeColor.find_by_name(color_name)

  step %{#{step_name} within "#color-#{color.id} td:first-child"}
end
