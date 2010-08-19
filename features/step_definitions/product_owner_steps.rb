Given /^the (.*) project has the backlogs plugin enabled$/ do |project_id|
  project = get_project(project_id)
  
  # Clear the project's versions
  project.versions.delete_all
  
  # Enable the backlogs plugin
  project.enabled_modules << EnabledModule.new(:name => 'backlogs')
  
  # Configure it properly
  story_trackers = Tracker.find(:all).map{|s| "#{s.id}"}
  task_tracker = "#{Tracker.create!(:name => 'Task').id}"
  plugin = Redmine::Plugin.find('redmine_backlogs')
  Setting["plugin_#{plugin.id}"] = {:story_trackers => story_trackers, :task_tracker => task_tracker }
end

Given /^I am a product owner of the (.*) project$/ do |project|
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.save!
end

Given /^the (.*) project has the following sprints:$/ do |project, table|
  @project = get_project(project)
  table.hashes.each do |version|
    version['project_id'] = @project.id
    Version.create! version
  end
end

Given /^I am viewing the (.*) master backlog$/ do |project|
  login_as_product_owner
  @project = get_project(project)
  visit url_for(:controller => 'backlogs', :action=>'index', :project_id => project)
end

When /^I move the (\d+)(?:st|nd|rd|th) story to the (\d+)(?:st|nd|rd|th) position$/ do |old_pos, new_pos|
  story = page.all(:css, "#product_backlog .stories .story .id")[old_pos.to_i-1]
  prev = page.all(:css, "#product_backlog .stories .story .id")[new_pos.to_i-2]
  story.should_not == nil
  page.submit :post, url_for(:controller => 'stories', :action => 'update', :project_id => @project), 
       {:id => story.text, :prev => (prev.nil? ? '' : prev.text)}
  response.should be_success
  @story = Story.find(story.text.to_i)
end

Then /^I should see the product backlog$/ do
  page.should have_css('#product_backlog')
end

Then /^the story should be at the top$/ do
  @story.position.should == 1
end