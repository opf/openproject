When /^I close (.+)$/ do |subject|
  @story = Story.find(:first, :conditions => "subject='#{subject}'")
  @story.should_not be_nil
  @story.update_attributes :status_id => IssueStatus.find(:first, :conditions => "name='Closed'").id
end

When /^I create the story$/ do
  page.driver.process :post, 
                      url_for(:controller => 'stories', :action => 'create'),
                      @story_params
end

When /^I create the task$/ do
  page.driver.process :post, 
                      url_for(:controller => 'tasks', :action => 'create'),
                      @task_params
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

When /^I request the server_variables resource$/ do
  visit url_for(:controller => 'server_variables', :action => 'index', :project_id => @project.id)
end

When /^I update the sprint$/ do
  page.driver.process :post,
                      url_for(:controller => 'backlogs', :action => 'update'),
                      @sprint_params
end

When /^I update the story$/ do
  page.driver.process :post,
                      url_for(:controller => 'stories', :action => 'update'),
                      @story_params
end

