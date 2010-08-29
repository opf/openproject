Given /^I am a member of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.save!
  login_as_member
end

Given /^I am a product owner of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.save!
  login_as_product_owner
end

Given /^I am a scrum master of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.save!
  login_as_scrum_master
end

Given /^I am a team member of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.permissions << :view_backlog
  role.save!
  login_as_team_member
end

Given /^I am viewing the master backlog$/ do
  visit url_for(:controller => 'backlogs', :action=>'index', :project_id => @project)
  page.driver.response.status.should == 200
end

Given /^I am viewing the burndown for (.+)$/ do |sprint_name|
  @sprint = Sprint.find(:first, :conditions => "name='#{sprint_name}'")
  visit url_for(:controller => 'backlogs', :action=>'burndown', :id => @sprint.id)
  page.driver.response.status.should == 200
end

Given /^I am viewing the taskboard for (.+)$/ do |sprint_name|
  @sprint = Sprint.find(:first, :conditions => "name='#{sprint_name}'")
  visit url_for(:controller => 'backlogs', :action=>'show', :id => @sprint.id)
  page.driver.response.status.should == 200
end

Given /^I set the (.+) of the story to (.+)$/ do |attribute, value|
  if attribute=="tracker"
    attribute="tracker_id"
    value = Tracker.find(:first, :conditions => "name='#{value}'").id
  end
  @story_params[attribute] = value
end

Given /^I set the (.+) of the task to (.+)$/ do |attribute, value|
  value = '' if value == 'an empty string'
  @task_params[attribute] = value
end

Given /^I want to create a story$/ do
  @story_params = initialize_story_params
end

Given /^I want to create a task for (.+)$/ do |story_subject|
  story = Story.find(:first, :conditions => "subject='#{story_subject}'")
  @task_params = initialize_task_params(story.id)
end

Given /^I want to edit the sprint named (.+)$/ do |name|
  sprint = Sprint.find(:first, :conditions => "name='#{name}'")
  sprint.should_not be_nil
  @sprint_params = sprint.attributes
end

Given /^I want to set the (.+) of the sprint to (.+)$/ do |attribute, value|
  value = '' if value == "an empty string"
  @sprint_params[attribute] = value
end

Given /^I want to update the story with subject (.+)$/ do |subject|
  @story = Story.find(:first, :conditions => "subject='#{subject}'")
  @story.should_not be_nil
  @story_params = @story.attributes
end

Given /^the (.*) project has the backlogs plugin enabled$/ do |project_id|
  @project = get_project(project_id)

  # Enable the backlogs plugin
  @project.enabled_modules << EnabledModule.new(:name => 'backlogs')

  # Configure the story and task trackers
  story_trackers = Tracker.find(:all).map{|s| "#{s.id}"}
  task_tracker = "#{Tracker.create!(:name => 'Task').id}"
  plugin = Redmine::Plugin.find('redmine_backlogs')
  Setting["plugin_#{plugin.id}"] = {:story_trackers => story_trackers, :task_tracker => task_tracker }

  # Make sure these trackers are enabled in the project
  @project.update_attributes :tracker_ids => (story_trackers << task_tracker)
end

Given /^the project has the following sprints:$/ do |table|
  @project.versions.delete_all
  table.hashes.each do |version|
    version['project_id'] = @project.id
    Sprint.create! version
  end
end

Given /^the project has the following stories in the product backlog:$/ do |table|
  @project.issues.delete_all
  prev_id = ''

  table.hashes.each do |story|
    params = initialize_story_params
    params['subject'] = story['subject']
    params['prev_id'] = prev_id

    # NOTE: We're bypassing the controller here because we're just
    # setting up the database for the actual tests. The actual tests,
    # however, should NOT bypass the controller
    s = Story.create_and_position params
    prev_id = s.id
  end
end

Given /^the project has the following stories in the following sprints:$/ do |table|
  @project.issues.delete_all
  prev_id = ''

  table.hashes.each do |story|
    params = initialize_story_params
    params['subject'] = story['subject']
    params['prev_id'] = prev_id
    params['fixed_version_id'] = (Sprint.find(:first, :conditions => "name='#{story['sprint']}'") || Sprint.new).id

    # NOTE: We're bypassing the controller here because we're just
    # setting up the database for the actual tests. The actual tests,
    # however, should NOT bypass the controller
    s = Story.create_and_position params
    prev_id = s.id
  end
end
