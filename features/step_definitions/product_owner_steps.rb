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
end

Given /^I am a product owner of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.save!
end

Given /^the project has the following sprints:$/ do |table|
  @project.versions.delete_all
  table.hashes.each do |version|
    version['project_id'] = @project.id
    Version.create! version
  end
end

Given /^the project has the following stories in the product backlog:$/ do |table|
  @project.issues.delete_all
  table.hashes.each do |story|
    story['project_id'] = @project.id
    story['tracker_id'] = Story.trackers[0]
    story['author_id']  = User.find(:first).id
    Story.create! story
  end
end

#
# Scenario steps
#

Given /^I am viewing the master backlog$/ do
  login_as_product_owner
  visit url_for(:controller => 'backlogs', :action=>'index', :project_id => @project)
end

When /^I move the (\d+)(?:st|nd|rd|th) story to the (\d+|last)(?:st|nd|rd|th)? position$/ do |old_pos, new_pos|
  @story_ids = page.all(:css, "#product_backlog .stories .story .id")

  story = @story_ids[old_pos.to_i-1]
  story.should_not == nil

  prev = if new_pos.to_i == 1
           nil
         elsif new_pos=='last'
           @story_ids.last
         else
           @story_ids[new_pos.to_i-1]
         end

  page.driver.process :post, 
                      url_for(:controller => 'stories', :action => 'update'),
                      {:id => story.text, :prev => (prev.nil? ? '' : prev.text), :project_id => @project.id}
  @story = Story.find(story.text.to_i)
end

Then /^I should see the product backlog$/ do
  page.should have_css('#product_backlog')
end

Then /^the story should be at the (top|bottom)$/ do |position|
  if position == 'top'
    @story.position.should == 1
  else
    @story.position.should == @story_ids.length
  end
end