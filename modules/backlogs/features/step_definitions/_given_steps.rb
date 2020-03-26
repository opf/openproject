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

Given /^I am logged out$/ do
  logout
end

Given /^I set the (.+) of the story to (.+)$/ do |attribute, value|
  if attribute == 'type'
    attribute = 'type_id'
    value = Type.find_by(name: value).id
  elsif attribute == 'status'
    attribute = 'status_id'
    value = Status.find_by(name: value).id
  elsif %w[backlog sprint].include? attribute
    attribute = 'version_id'
    value = Version.find_by(name: value).id
  end
  @story_params[attribute] = value
end

Given /^I set the (.+) of the task to (.+)$/ do |attribute, value|
  value = '' if value == 'an empty string'
  @task_params[attribute] = value
end

Given /^I want to create a story(?: in [pP]roject "(.+?)")?$/ do |project_name|
  project = get_project(project_name)
  @story_params = initialize_story_params(project)
end

Given /^I want to create a task for (.+)(?: in [pP]roject "(.+?)")?$/ do |story_subject, project_name|
  project = get_project(project_name)

  story = Story.find_by(subject: story_subject)
  @task_params = initialize_task_params(project, story)
end

Given /^I want to create an impediment for (.+?)(?: in [pP]roject "(.+?)")?$/ do |sprint_subject, project_name|
  project = get_project(project_name)
  sprint = Sprint.find_by(name: sprint_subject)
  @impediment_params = initialize_impediment_params(project, sprint.id)
end

Given /^I want to edit the task named (.+)$/ do |task_subject|
  task = Task.find_by(subject: task_subject)
  task.should_not be_nil
  @task_params = HashWithIndifferentAccess.new(task.attributes)
  @task_params['parent_id'] = task.parent_id
  @task_params
end

Given /^I want to edit the impediment named (.+)$/ do |impediment_subject|
  impediment = Task.find_by(subject: impediment_subject)
  impediment.should_not be_nil
  @impediment_params = HashWithIndifferentAccess.new(impediment.attributes)
end

Given /^I want to edit the sprint named (.+)$/ do |name|
  sprint = Sprint.find_by(name: name)
  sprint.should_not be_nil
  @sprint_params = HashWithIndifferentAccess.new(sprint.attributes)
end

Given /^I want to indicate that the impediment blocks (.+)$/ do |blocks_csv|
  blocks_csv = Story.where(subject: blocks_csv.split(', ')).pluck(:id).join(',')
  @impediment_params[:blocks] = blocks_csv
end

Given /^I want to set the (.+) of the sprint to (.+)$/ do |attribute, value|
  value = '' if value == 'an empty string'
  @sprint_params[attribute] = value
end

Given /^I want to set the (.+) of the impediment to (.+)$/ do |attribute, value|
  value = '' if value == 'an empty string'
  @impediment_params[attribute] = value
end

Given /^I want to edit the story with subject (.+)$/ do |subject|
  @story = Story.find_by(subject: subject)
  @story.should_not be_nil
  @story_params = HashWithIndifferentAccess.new(@story.attributes)
end

Given /^the backlogs module is initialized(?: in [pP]roject "(.*)")?$/ do |project_name|
  project = get_project(project_name)

  step 'the following types are configured to track stories:', table(%{
    | Story |
    | Epic |
  })
  step 'the type "Task" is configured to track tasks'
  step "the project \"#{project.name}\" uses the following types:", table(%{
    | Story |
    | Task |
  })
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following sprints:$/ do |project_name, table|
  project = get_project(project_name)

  table.hashes.each do |version|
    ['effective_date', 'start_date'].each do |date_attr|
      version[date_attr] = eval(version[date_attr]).strftime('%Y-%m-%d') if version[date_attr].match(/^(\d+)\.(year|month|week|day|hour|minute|second)(s?)\.(ago|from_now)$/)
    end
    sprint = Sprint.new version
    sprint.project = project
    sprint.save!

    vs = sprint.version_settings.build
    vs.project = project
    vs.display_left!
    vs.save!
  end
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following (?:product )?(?:owner )?backlogs?:$/ do |project_name, table|
  project = get_project(project_name)

  table.raw.each do |row|
    version = Version.create!(project: project, name: row.first)

    vs = version.version_settings.build
    vs.project = project
    vs.display_right!
    vs.save!
  end
end

Given /^the [pP]roject(?: "(.+?)")? has the following stories in the following (?:product )?(?:owner )?backlogs:$/ do |project_name, table|
  if project_name
    step %{the project "#{project_name}" has the following stories in the following sprints:}, table
  else
    step 'the project has the following stories in the following sprints:', table
  end
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following stories in the following sprints:$/ do |project_name, table|
  project = get_project(project_name)

  project.work_packages.destroy_all
  prev_id = ''

  table.hashes.each do |story|
    params = initialize_story_params(project)
    params['parent'] = WorkPackage.find_by(subject: story['parent'])
    params['subject'] = story['subject']
    params['version_id'] = Version.find_by(name: story['sprint'] || story['backlog']).id
    params['story_points'] = story['story_points']
    params['status'] =  if story['status']
                          Status.find_by(name: story['status'])
                        else
                          Status.default
                        end
    params['type_id'] = Type.find_by(name: story['type']).id if story['type']
    params['priority'] = if story['priority']
                           IssuePriority.find_by(name: story['priority'])
                         else
                           IssuePriority.default
                         end

    params.delete 'position'
    # NOTE: We're bypassing the controller here because we're just
    # setting up the database for the actual tests. The actual tests,
    # however, should NOT bypass the controller
    s = Story.create!(params.merge(project: params[:project], author: params['author']))
    s.move_after(prev_id) unless prev_id.blank?
    prev_id = s.id
  end
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following tasks:$/ do |project_name, table|
  project = get_project(project_name)

  User.current = User.first

  as_admin do
    table.hashes.each do |task|
      story = Story.find_by(subject: task['parent'])
      params = initialize_task_params(project, story)
      params['subject'] = task['subject']
      params['project_id'] = project.id
      params['status'] = if task['status']
                           Status.find_by(name: story['task'])
                         else
                           Status.default
                         end
      params['priority'] = if task['priority']
                             IssuePriority.find_by(name: task['priority'])
                           else
                             IssuePriority.default
                           end

      # NOTE: We're bypassing the controller here because we're just
      # setting up the database for the actual tests. The actual tests,
      # however, should NOT bypass the controller
      Task.create!(params)
    end
  end
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following work_packages:$/ do |project_name, table|
  project = get_project(project_name)

  User.current = User.first

  as_admin do
    table.hashes.each do |task|
      parent = WorkPackage.find_by(subject: task['parent'])
      type = Type.find_by(name: task['type'])
      params = initialize_work_package_params(project, type, parent)
      params['subject'] = task['subject']
      version = Version.find_by(name: task['sprint'] || task['backlog'])
      params['version_id'] = version.id if version
      params['priority'] = if task['priority']
                             IssuePriority.find_by(name: task['priority'])
                           else
                             IssuePriority.default
                           end

      # NOTE: We're bypassing the controller here because we're just
      # setting up the database for the actual tests. The actual tests,
      # however, should NOT bypass the controller
      work_package = WorkPackage.new
      work_package.attributes = params
      work_package.save!
    end
  end
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following impediments:$/ do |project_name, table|
  project = get_project(project_name)

  User.current = User.first

  as_admin do
    table.hashes.each do |impediment|
      sprint = Sprint.find_by(name: impediment['sprint'])
      blocks = Story.where(subject: impediment['blocks'].split(', ')).pluck(:id)
      params = initialize_impediment_params(project, sprint)
      params['subject'] = impediment['subject']
      params['blocks_ids'] = blocks.join(',')
      params['project_id'] = project.id
      params['priority'] = if impediment['priority']
                             IssuePriority.find_by(name: impediment['priority'])
                           else
                             IssuePriority.default
                           end

      # NOTE: We're bypassing the controller here because we're just
      # setting up the database for the actual tests. The actual tests,
      # however, should NOT bypass the controller
      Impediment.create!(params)
    end
  end
end

Given /^I have set my API access key$/ do
  Setting[:rest_api_enabled] = 1
  User.current.reload
  User.current.api_key.should_not be_nil
  @api_key = User.current.api_key
end

Given /^I have guessed an API access key$/ do
  Setting[:rest_api_enabled] = 1
  @api_key = 'guess'
end

Given /^I have set the content for wiki page (.+) to (.+)$/ do |title, content|
  page = @project.wiki.find_page(title)
  if !page
    page = WikiPage.new(wiki: @project.wiki, title: title)
    page.content = WikiContent.new
    page.save
  end

  page.content.text = content
  page.save.should be_truthy
end

Given /^I have made (.+) the template page for sprint notes/ do |title|
  Setting.plugin_openproject_backlogs = Setting.plugin_openproject_backlogs.merge('wiki_template' => title)
end

Given /^there are no stories in the [pP]roject$/ do
  @project.work_packages.delete_all
end

Given /^the type "(.+?)" is configured to track tasks$/ do |type_name|
  type = Type.find_by(name: type_name)
  type = FactoryBot.create(:type, name: type_name) if type.blank?

  Setting.plugin_openproject_backlogs = Setting.plugin_openproject_backlogs.merge('task_type' => type.id)
end

Given /^the following types are configured to track stories:$/ do |table|
  story_types = []
  table.raw.each do |line|
    name = line.first
    type = Type.find_by(name: name)

    type = FactoryBot.create(:type, name: name) if type.blank?
    story_types << type
  end

  # otherwise the type id's from the previous test are still active
  WorkPackage.instance_variable_set(:@backlogs_types, nil)

  Setting.plugin_openproject_backlogs = Setting.plugin_openproject_backlogs.merge('story_types' => story_types.map(&:id))
end

Given /^the [tT]ype(?: "([^\"]*)")? has for the Role "(.+?)" the following workflows:$/ do |type_name, role_name, table|
  role = Role.find_by(name: role_name)
  type = Type.find_by(name: type_name)

  type.workflows = []
  table.hashes.each do |workflow|
    old_status = Status.find_by(name: workflow['old_status']).id
    new_status = Status.find_by(name: workflow['new_status']).id
    type.workflows.build(old_status_id: old_status, new_status_id: new_status, role: role)
  end
  type.save!
end

Given /^the status of "([^"]*)" is "([^"]*)"$/ do |work_package_subject, status_name|
  s = WorkPackage.find_by(subject: work_package_subject)
  s.status = Status.find_by(name: status_name)
  s.save!
end

Given /^there is the single default export card configuration$/ do
  config = ExportCardConfiguration.create!(name: 'Default',
                                           per_page: 1,
                                           page_size: 'A4',
                                           orientation: 'landscape',
                                           rows: "group1:\n  has_border: false\n  rows:\n    row1:\n      height: 50\n      priority: 1\n      columns:\n        id:\n          has_label: false")
end
