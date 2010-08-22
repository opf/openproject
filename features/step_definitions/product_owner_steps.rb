#
# Debugging steps
# NOTE: You may also use "Then show me the page" to display the browser view
#
Then /^show me the list of stories$/ do
  puts "\n"
  puts "\t------------------------------------"
  puts "\t| id  | position | subject         |"
  puts "\t------------------------------------"
  Story.find(:all, :conditions => "project_id=#{@project.id}", :order => "position ASC").each do |story|
    puts "\t| #{story.id.to_s.ljust(3)} | #{story.position.to_s.ljust(8)} | #{story.subject.to_s.ljust(15)} |"
  end
  puts "\t------------------------------------\n\n"
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
end

Given /^I am a product owner of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.save!
  login_as_product_owner
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
  prev_id = ''

  table.hashes.each do |story|
    params = initialize_story_params
    params['subject'] = story['subject']
    params['prev_id'] = prev_id

    # NOTE: We're bypassing the controller here because we're just
    # setting up the database for the actual tests. The actual tests,
    # however, should NOT bypass the controller
    s = Story.create_and_position! params
    prev_id = s.id
  end

end

#
# Scenario steps
#

Given /^I am viewing the master backlog$/ do
  visit url_for(:controller => 'backlogs', :action=>'index', :project_id => @project)
end

Given /^I want to create a new story$/ do
  @story_params = initialize_story_params
end

Given /^I set the (.+) of the story to (.+)$/ do |attribute, value|
  @story_params[attribute] = value
end

When /^I move the (\d+)(?:st|nd|rd|th) story to the (\d+|last)(?:st|nd|rd|th)? position$/ do |old_pos, new_pos|
  @story_ids = page.all(:css, "#product_backlog .stories .story .id")

  story = @story_ids[old_pos.to_i-1]
  story.should_not == nil

  prev = if new_pos.to_i == 1
           nil
         elsif new_pos=='last'
           @story_ids.last
         elsif old_pos.to_i > new_pos.to_i
           @story_ids[new_pos.to_i-2]
         else
           @story_ids[new_pos.to_i-1]
         end

  page.driver.process :post, 
                      url_for(:controller => 'stories', :action => 'update'),
                      {:id => story.text, :prev => (prev.nil? ? '' : prev.text), :project_id => @project.id}

  @story = Story.find(story.text.to_i)
end

When /^I create the story$/ do
  page.driver.process :post, 
                      url_for(:controller => 'stories', :action => 'create'),
                      @story_params
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

Then /^the (\d+)(?:st|nd|rd|th) story should be (.+)$/ do |position, subject|
  story = Story.find(:first, :conditions => "position=#{position}")
  story.should_not be_nil
  story.subject.should == subject
end

Then /^the (\d+)(?:st|nd|rd|th) position should be unique$/ do |position|
  Story.find(:all, :conditions => "position=#{position}").length.should == 1
end
