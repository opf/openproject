#
# Background steps
#

Given /^I am a product owner of the project$/ do
  role = Role.find(:first, :conditions => "name='Manager'")
  role.permissions << :manage_backlog
  role.save!
  login_as_product_owner
end


#
# Scenario steps
#

Given /^I want to create a new story$/ do
  @story_params = initialize_story_params
end

Given /^I want to update the story with subject (.+)$/ do |subject|
  @story = Story.find(:first, :conditions => "subject='#{subject}'")
  @story.should_not be_nil
  @story_params = @story.attributes
end

Given /^I set the (.+) of the story to (.+)$/ do |attribute, value|
  if attribute=="tracker"
    attribute="tracker_id"
    value = Tracker.find(:first, :conditions => "name='#{value}'").id
  end
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

When /^I update the story$/ do
  page.driver.process :post,
                      url_for(:controller => 'stories', :action => 'update'),
                      @story_params
end

When /^I close (.+)$/ do |subject|
  @story = Story.find(:first, :conditions => "subject='#{subject}'")
  @story.should_not be_nil
  @story.update_attributes :status_id => IssueStatus.find(:first, :conditions => "name='Closed'").id
end


Then /^I should see the product backlog$/ do
  page.should have_css('#product_backlog')
end

Then /^I should see (\d+) sprint backlogs$/ do |count|
  sprint_backlogs = page.all(:css, ".sprint")
  sprint_backlogs.length.should == count.to_i
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

Then /^the status of the story should be set as (.+)$/ do |status|
  @story.reload
  @story.status.name.downcase.should == status
end

Then /^the story should have a (.+) of (.+)$/ do |attribute, value|
  @story.reload
  if attribute=="tracker"
    attribute="tracker_id"
    value = Tracker.find(:first, :conditions => "name='#{value}'").id
  elsif attribute=="position"
    value = value.to_i
  end
  @story[attribute].should == value
end


def login_as_product_owner
  visit url_for(:controller => 'account', :action=>'login')
  fill_in 'username', :with => 'jsmith'
  fill_in 'password', :with => 'jsmith'
  click_button 'Login »'
  @user = User.find(:first, :conditions => "login='jsmith'")
end

def initialize_story_params
  @story = Story.new.attributes
  @story['project_id'] = @project.id
  @story['tracker_id'] = Story.trackers.first
  @story['author_id']  = @user.id
  @story
end
