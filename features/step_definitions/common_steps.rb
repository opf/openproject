#
# Debugging steps
# NOTE: You may also use "Then show me the page" to display the browser view
#
Then /^show me the list of stories$/ do
  stories = Story.find(:all, :conditions => "project_id=#{@project.id}", :order => "position ASC")
  subject_max = (stories.map{|s| s.subject} << "subject").sort{|a,b| a.length <=> b.length}.last.length
  sprints = @project.versions.find(:all)
  sprint_max = (sprints.map{|s| s.name} << "sprint").sort{|a,b| a.length <=> b.length}.last.length

  puts "\n"
  puts "\t| id  | position | #{'subject'.ljust(subject_max)} | #{'sprint'.ljust(sprint_max)} |"
  stories.each do |story|
    puts "\t| #{story.id.to_s.ljust(3)} | #{story.position.to_s.ljust(8)} | #{story.subject.ljust(subject_max)} | #{(story.fixed_version_id.nil? ? Sprint.new : Sprint.find(story.fixed_version_id)).name.ljust(sprint_max)} |"
  end
  puts "\n\n"
end

#
# Background steps
#

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

Given /^I am a member of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.save!
  login_as_member
end



#
# Scenario steps
#

Given /^I am viewing the master backlog$/ do
  visit url_for(:controller => 'backlogs', :action=>'index', :project_id => @project)
end

When /^I request the server_variables resource$/ do
  visit url_for(:controller => 'server_variables', :action => 'index', :project_id => @project.id)
end

Then /^the request should complete successfully$/ do
  page.driver.response.status.should == 200
end

def get_project(identifier)
  Project.find(:first, :conditions => "identifier='#{identifier}'")
end

def login_as_member
  visit url_for(:controller => 'account', :action=>'login')
  fill_in 'username', :with => 'jsmith'
  fill_in 'password', :with => 'jsmith'
  click_button 'Login »'
  @user = User.find(:first, :conditions => "login='jsmith'")
end