#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

When /^I create the impediment$/ do
  page.driver.post backlogs_project_sprint_impediments_url(
    *@impediment_params.values_at('project_id', 'version_id')
  ), @impediment_params.except('author_id', 'author')
end

When /^I create the story$/ do
  page.driver.post backlogs_project_sprint_stories_url(
    *@story_params.values_at('project_id', 'version_id')
  ), @story_params.except('author_id', 'author')
end

When /^I create the task$/ do
  page.driver.post backlogs_project_sprint_tasks_url(
    *@task_params.values_at('project_id', 'version_id')
  ), @task_params.except('author_id', 'author')
end

When /^I move the (story|item|task) named (.+) below (.+)$/ do |type, story_subject, prev_subject|
  work_package_class = if type.strip == 'task' then Task else Story end
  story = work_package_class.find_by(subject: story_subject.strip)
  prev  = work_package_class.find_by(subject: prev_subject.strip)

  attributes = story.attributes
  attributes[:prev] = prev.id

  if type == 'task'
    # #attributes returns the parent_id to always be nil
    attributes['parent_id'] = story.parent_id
  else
    attributes[:version_id] = prev.version_id
  end

  project = Project.find(attributes['project_id'])
  sprint  = prev.version

  page.driver.post polymorphic_url(
    [:backlogs, project, sprint.becomes(Sprint), story]
  ), attributes.merge('_method' => 'put')
end

When /^I move the story named (.+) (up|down) to the (\d+)(?:st|nd|rd|th) position of the sprint named (.+)$/ do |story_subject, direction, position, sprint_name|
  position = position.to_i
  story = Story.find_by(subject: story_subject)
  sprint = Sprint.find_by(name: sprint_name)
  story.version = sprint

  attributes = story.attributes
  attributes[:prev] = if position == 1
                        ''
                      else
                        stories = Story.where(version_id: sprint.id, type_id: Story.types).order(Arel.sql('position ASC'))
                        raise "You indicated an invalid position (#{position}) in a sprint with #{stories.length} stories" if 0 > position or position > stories.length
                        stories[position - (direction == 'up' ? 2 : 1)].id
                      end

  page.driver.post backlogs_project_sprint_story_url(
    *attributes.values_at('project_id', 'version_id', 'id')
  ), attributes.merge('_method' => 'put')
end

When /^I move the (\d+)(?:st|nd|rd|th) story to the (\d+|last)(?:st|nd|rd|th)? position$/ do |old_pos, new_pos|
  @story_ids = page.all(:css, '#owner_backlogs_container .stories .story .id')

  story = @story_ids[old_pos.to_i - 1]
  story.should_not == nil

  prev = if new_pos.to_i == 1
           nil
         elsif new_pos == 'last'
           @story_ids.last
         elsif old_pos.to_i > new_pos.to_i
           @story_ids[new_pos.to_i - 2]
         else
           @story_ids[new_pos.to_i - 1]
         end

  @story = Story.find(story.text.to_i)

  page.driver.post backlogs_project_sprint_story_url(
    @project.id,
    @story.version_id,
    @story.id
  ), prev: (prev.nil? ? '' : prev.text), '_method' => 'put'
end

When /^I update the impediment$/ do
  page.driver.post backlogs_project_sprint_impediment_url(
    *@impediment_params.values_at('project_id', 'version_id', 'id')
  ), @impediment_params.merge('_method' => 'put')
end

When /^I update the sprint$/ do
  page.driver.post backlogs_project_sprint_url(
    *@sprint_params.values_at('project_id', 'id')
  ), @sprint_params.merge('_method' => 'put')
end

When /^I update the story$/ do
  page.driver.post backlogs_project_sprint_story_url(
    *@story_params.values_at('project_id', 'version_id', 'id')
  ), @story_params.merge('_method' => 'put')
end

When /^I update the task$/ do
  page.driver.post backlogs_project_sprint_task_url(
    *@task_params.values_at('project_id', 'version_id', 'id')
  ), @task_params.merge('_method' => 'put')
end

When /^I view the master backlog$/ do
  visit url_for(controller: '/projects', action: :show, id: @project)
  click_link('Backlogs')
end

When /^I view the stories of (.+) in the work_packages tab/ do |sprint_name|
  sprint = Sprint.find_by(name: sprint_name)
  visit url_for(controller: '/rb_queries', action: :show, project_id: sprint.project, sprint_id: sprint, only_path: true)
end

When /^I view the stories in the work_packages tab/ do
  visit url_for(controller: '/rb_queries', action: :show, project_id: @project, only_path: true)
end

# WARN: Depends on deprecated behavior of path_for('the task board for
#       "sprint name"')
When /^I view the sprint notes$/ do
  visit url_for(controller: '/rb_wikis', action: 'show', sprint_id: @sprint, project_id: @project)
end

# WARN: Depends on deprecated behavior of path_for('the task board for
#       "sprint name"')
When /^I edit the sprint notes$/ do
  visit url_for(controller: '/rb_wikis', action: 'edit', sprint_id: @sprint, project_id: @project)
end

When /^I follow "(.+?)" of the "(.+?)" (?:backlogs )?menu$/ do |link, backlog_name|
  sprint = Sprint.find_by(name: backlog_name)
  step %{I follow "#{link}" within "#backlog_#{sprint.id} .menu"}
end

When /^I open the "(.+?)" backlogs(?: )?menu/ do |backlog_name|
  sprint = Sprint.find_by(name: backlog_name)
  find(:css, "#backlog_#{sprint.id} .menu > div").click
end

When /^I close the "(.+?)" backlogs(?: )?menu/ do |backlog_name|
  sprint = Sprint.find_by(name: backlog_name)
  step %{I stop hovering over "#backlog_#{sprint.id} .menu"}
end

When /^I click on the text "(.+?)"$/ do |locator|
  expect(page)
    .to have_content(locator)
  find(:xpath, %{//*[contains(text(), "#{locator}")]}).click
end

When /^I click on the link on the modal window with text "(.+?)"$/ do |locator|
  browser = page.driver.browser
  browser.switch_to.frame('modalIframe')
  click_link(locator)
end

When /^I click on the element with class "([^"]+?)"$/ do |locator|
  find(:css, ".#{locator}").click
end

When /^I confirm the story form$/ do
  find(:css, 'input[name=subject]').native.send_key :return
  step 'I wait for AJAX requests to finish'
  step 'I should not see ".saving"'
end

When /^I fill in the ids of the (tasks|work_packages|stories) "(.+?)" for "(.+?)"$/ do |model_name, subjects, field|
  model = Kernel.const_get(model_name.classify)
  ids = subjects.split(/,/).map { |subject| model.find_by(subject: subject).id }

  step %{I fill in "#{ids.join(', ')}" for "#{field}"}
end

When /^I click on the impediment called "(.+?)"$/ do |impediment_name|
  step %{I click on the text "#{impediment_name}"}
end

When /^I click to add a new task for story "(.+?)"$/ do |story_name|
  expect(page)
    .to have_content(story_name)

  story = Story.find_by(subject: story_name)

  find("tr.story_#{story.id} td.add_new").click
end

When /^I fill in the id of the work_package "(.+?)" as the parent work_package$/ do |work_package_name|
  work_package = WorkPackage.find_by(subject: work_package_name)

  # TODO: Simplify once the work_package#edit/update action is implemented
  find('#work_package_parent_id, #work_package_parent_id', visible: false).set(work_package.id)
end

When /^the request on task "(.+?)" is finished$/ do |task_name|
  # Wait for the modal link of this task to appear...
  elements = page.find(:xpath, "//div[contains(., '#{task_name}') and contains(@class,'task')]/descendant::a[contains(@href, .)]")
  # ...by selecting the task board card for a specific task and then go for the
  # link with the id only appearing after the task was saved
end

When /^I follow the link to add a subtask$/ do
  step 'I follow "Relations"'
  step 'I click "Children"'
  step 'I press "Add child"'
end

When /^I change the fold state of a version$/ do
  find('.backlog .toggler').click
end

When /^I click on the Export link$/ do
  click_link('Export')
end

When(/^I click on the link for the story "(.*?)"$/) do |subject|
  story = Story.find_by(subject: subject)

  within("#story_#{story.id}") do
    click_link(story.id)
  end
end
