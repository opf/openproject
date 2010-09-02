Given /^I am a product owner of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :view_master_backlog
  role.permissions << :create_stories
  role.permissions << :update_stories
  role.save!
  login_as_product_owner
end

Given /^I am a scrum master of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :view_master_backlog
  role.permissions << :view_sprints
  role.save!
  login_as_scrum_master
end

Given /^I am a team member of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :view_master_backlog
  role.permissions << :view_sprints
  role.permissions << :create_tasks
  # role.permissions << :update_tasks
  # role.permissions << :create_impediments
  # role.permissions << :update_impediments
  role.save!
  login_as_team_member
end

Given /^I am viewing the master backlog$/ do
  visit url_for(:controller => :rb_master_backlogs, :action => :show, :id => @project)
  page.driver.response.status.should == 200
end

Given /^I am viewing the burndown for (.+)$/ do |sprint_name|
  @sprint = Sprint.find(:first, :conditions => "name='#{sprint_name}'")
  visit url_for(:controller => :rb_burndown_charts, :action => :show, :id => @sprint.id)
  page.driver.response.status.should == 200
end

Given /^I am viewing the taskboard for (.+)$/ do |sprint_name|
  @sprint = Sprint.find(:first, :conditions => "name='#{sprint_name}'")
  visit url_for(:controller => :rb_sprints, :action => :show, :id => @sprint.id)
  page.driver.response.status.should == 200
end

Given /^I set the (.+) of the story to (.+)$/ do |attribute, value|
  if attribute=="tracker"
    attribute="tracker_id"
    value = Tracker.find(:first, :conditions => "name='#{value}'").id
  elsif attribute=="status"
    attribute="status_id"
    value = IssueStatus.find(:first, :conditions => "name='#{value}'").id
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
    ['effective_date', 'sprint_start_date'].each do |date_attr|
      version[date_attr] = eval(version[date_attr]).strftime("%Y-%m-%d") if version[date_attr].match(/^(\d+)\.(year|month|week|day|hour|minute|second)(s?)\.(ago|from_now)$/)
    end
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

Given /^I am viewing the issues list$/ do
  visit url_for(:controller => 'issues', :action=>'index', :project_id => @project)
  page.driver.response.status.should == 200
end

Given /^I have set my API access key$/ do
  Setting[:rest_api_enabled] = 1
  @user.reload
  @user.api_key.should_not be_nil
end

Given /^I have set the content for wiki page "([^"]+)" to "([^"]+)"$/ do |title, content|
  title = Wiki.titleize(title)
  page = @project.wiki.find_page(title)
  if ! page
    page = WikiPage.new(:wiki => @project.wiki, :title => title)
    page.content = WikiContent.new
    page.save
  end

  page.content.text = content
  page.save
end

Given /^I have made "([^"]+)" the template page for sprint notes/ do |title|
  Setting.plugin_redmine_backlogs[:wiki_template] = Wiki.titleize(title)
end
