#
# Background steps
#

Given /^I am a team member of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.save!
  login_as_team_member
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

#
# Scenario steps
#

Given /^I am viewing the taskboard for (.+)$/ do |sprint_name|
  sprint = Sprint.find(:first, :conditions => "name='#{sprint_name}'")
  visit url_for(:controller => 'backlogs', :action=>'show', :project_id => @project, :id => sprint.id)
end

Given /^I want to create a task for (.+)$/ do |story_subject|
  story = Story.find(:first, :conditions => "subject='#{story_subject}'")
  @task_params = initialize_task_params(story.id)
end

Given /^I set the (.+) of the task to (.+)$/ do |attribute, value|
  @task_params[attribute] = value
end

When /^I create the task$/ do
  page.driver.process :post, 
                      url_for(:controller => 'tasks', :action => 'create'),
                      @task_params
end

Then /^the (\d+)(?:st|nd|rd|th) task for (.+) should be (.+)$/ do |position, story_subject, task_subject|
  pending # express the regexp above with the code you wish you had
end

def login_as_team_member
  visit url_for(:controller => 'account', :action=>'login')
  fill_in 'username', :with => 'jsmith'
  fill_in 'password', :with => 'jsmith'
  click_button 'Login »'
  @user = User.find(:first, :conditions => "login='jsmith'")
end

def initialize_task_params(story_id)
  params = Task.new.attributes
  params['project_id'] = @project.id
  params['tracker_id'] = Task.tracker
  params['author_id']  = @user.id
  params['parent_issue_id'] = story_id
  params['status_id'] = IssueStatus.find(:first).id
  params
end
