Then /^I should see (\d+) sprint backlogs$/ do |count|
  sprint_backlogs = page.all(:css, ".sprint")
  sprint_backlogs.length.should == count.to_i
end

Then /^I should see the burndown chart$/ do
  page.should have_css("#burndown_#{@sprint.id.to_s}")
end

Then /^I should see the taskboard$/ do
  page.should have_css('#taskboard')
end

Then /^I should see the product backlog$/ do
  page.should have_css('#product_backlog')
end

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

Then /^the request should complete successfully$/ do
  page.driver.response.status.should == 200
end

Then /^the (\d+)(?:st|nd|rd|th) story should be (.+)$/ do |position, subject|
  story = Story.find(:first, :conditions => "position=#{position}")
  story.should_not be_nil
  story.subject.should == subject
end

Then /^the (\d+)(?:st|nd|rd|th) position should be unique$/ do |position|
  Story.find(:all, :conditions => "position=#{position}").length.should == 1
end

Then /^the (\d+)(?:st|nd|rd|th) task for (.+) should be (.+)$/ do |position, story_subject, task_subject|
  story = Story.find(:first, :conditions => "subject='#{story_subject}'")
  story.children[position.to_i - 1].subject.should == task_subject
end

Then /^the sprint should be updated accordingly$/ do
  sprint = Sprint.find(@sprint_params['id'])
  
  sprint.attributes.each_key do |key|
    unless ['updated_on', 'created_on'].include?(key)
      @sprint_params[key].should == (key.include?('_date') ? sprint[key].strftime("%Y-%m-%d") : sprint[key])
    end
  end
end

Then /^the status of the story should be set as (.+)$/ do |status|
  @story.reload
  @story.status.name.downcase.should == status
end

Then /^the story should be at the (top|bottom)$/ do |position|
  if position == 'top'
    @story.position.should == 1
  else
    @story.position.should == @story_ids.length
  end
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