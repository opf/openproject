Then /^(.+) should be in the (\d+)(?:st|nd|rd|th) position of the sprint named (.+)$/ do |story_subject, position, sprint_name|
  position = position.to_i
  story = Story.find(:first, :conditions => ["subject=? and name=?", story_subject, sprint_name], :joins => :fixed_version)
  story_position(story).should == position.to_i
end

Then /^I should see (\d+) (?:product )?owner backlogs$/ do |count|
  sprint_backlogs = page.all(:css, "#owner_backlogs_container .sprint")
  sprint_backlogs.length.should == count.to_i
end

Then /^I should see (\d+) sprint backlogs$/ do |count|
  sprint_backlogs = page.all(:css, "#sprint_backlogs_container .sprint")
  sprint_backlogs.length.should == count.to_i
end

Then /^I should see the burndown chart for sprint "(.+?)"$/ do |sprint|
  sprint = Sprint.find_by_name(sprint)

  page.should have_css("#burndown_#{sprint.id.to_s}")
end

Then /^I should see the Issues page$/ do
  page.should have_css("#query_form")
end

Then /^I should see the taskboard$/ do
  page.should have_css('#taskboard')
end

Then /^I should see the product backlog$/ do
  page.should have_css('#owner_backlogs_container')
end

Then /^I should see (\d+) stories in (?:the )?"(.+?)"$/ do |count, backlog_name|
  sprint = Sprint.find_by_name(backlog_name)
  page.all(:css, "#backlog_#{sprint.id} .story").size.should == count.to_i
end

Then /^the velocity of "(.+?)" should be "(.+?)"$/ do |backlog_name, velocity|
  sprint = Sprint.find_by_name(backlog_name)
  page.find(:css, "#backlog_#{sprint.id} .velocity").text.should == velocity
end

Then /^show me the list of sprints$/ do
  sprints = Sprint.find(:all, :conditions => ["project_id=?", @project.id])

  puts "\n"
  puts "\t| #{'id'.ljust(3)} | #{'name'.ljust(18)} | #{'start_date'.ljust(18)} | #{'effective_date'.ljust(18)} | #{'updated_on'.ljust(20)}"
  sprints.each do |sprint|
    puts "\t| #{sprint.id.to_s.ljust(3)} | #{sprint.name.to_s.ljust(18)} | #{sprint.start_date.to_s.ljust(18)} | #{sprint.effective_date.to_s.ljust(18)} | #{sprint.updated_on.to_s.ljust(20)} |"
  end
  puts "\n\n"
end

Then /^show me the list of stories$/ do
  stories = Story.find(:all, :conditions => "project_id=#{@project.id}", :order => "position ASC")
  subject_max = (stories.map{|s| s.subject} << "subject").sort{|a,b| a.length <=> b.length}.last.length
  sprints = @project.versions.find(:all)
  sprint_max = (sprints.map{|s| s.name} << "sprint").sort{|a,b| a.length <=> b.length}.last.length

  puts "\n"
  puts "\t| #{'id'.ljust(5)} | #{'position'.ljust(8)} | #{'status'.ljust(12)} | #{'rank'.ljust(4)} | #{'subject'.ljust(subject_max)} | #{'sprint'.ljust(sprint_max)} |"
  stories.each do |story|
    puts "\t| #{story.id.to_s.ljust(5)} | #{story.position.to_s.ljust(8)} | #{story.status.name[0,12].ljust(12)} | #{story.rank.to_s.ljust(4)} | #{story.subject.ljust(subject_max)} | #{(story.fixed_version_id.nil? ? Sprint.new : Sprint.find(story.fixed_version_id)).name.ljust(sprint_max)} |"
  end
  puts "\n\n"
end

Then /^(.+) should be the higher (story|item|task) of (.+)$/ do |higher_subject, type, lower_subject|
  issue_class = (type == 'task') ? Task : Story

  higher = issue_class.find(:all, :conditions => { :subject => higher_subject })
  higher.length.should == 1

  lower = issue_class.find(:all, :conditions => { :subject => lower_subject })
  lower.length.should == 1

  if type == "task"
    lower.first.id.should == higher.first.right_sibling.id
  else
    lower.first.higher_item.id.should == higher.first.id
  end
end

Then /^the request should complete successfully$/ do
  page.driver.response.status.should == 200
end

Then /^the request should fail$/ do
  page.driver.response.status.should == 401
end

Then /^the (\d+)(?:st|nd|rd|th) story in (?:the )?"(.+?)" should be "(.+)"$/ do |position, version_name, subject|
  version = Version.find_by_name(version_name)
  story = Story.at_rank(@project.id, version.id, position.to_i)
  story.should_not be_nil
  story.subject.should == subject
end

Then /^the (\d+)(?:st|nd|rd|th) story in (?:the )?"(.+?)" should be in the "(.+?)" tracker$/ do |position, version_name, tracker_name|
  version = Version.find_by_name(version_name)
  tracker = Tracker.find_by_name(tracker_name)
  story = Story.at_rank(@project.id, version.id, position.to_i)
  story.should_not be_nil
  story.tracker.should == tracker
end

Then /^the (\d+)(?:st|nd|rd|th) story in (?:the )?"(.+?)" should have the ID of "(.+?)"$/ do |position, version_name, subject|
  version = Version.find_by_name(version_name)
  actual_story = Issue.find_by_subject_and_fixed_version_id(subject, version)
  Then %%I should see "#{actual_story.id}" within ".story:nth-child(#{position}) .id div.t"%
end

Then /^all positions should be unique within versions$/ do
  Story.find_by_sql("select project_id, fixed_version_id, position, count(*) as dups from issues where not position is NULL group by project_id, fixed_version_id, position having count(*) > 1").length.should == 0
end

Then /^the (\d+)(?:st|nd|rd|th) task for (.+) should be (.+)$/ do |position, story_subject, task_subject|
  story = Story.find(:first, :conditions => ["subject=?", story_subject])
  story.children[position.to_i - 1].subject.should == task_subject
end

Then /^the server should return an update error$/ do
  page.driver.response.status.should == 400
end

Then /^the server should return (\d+) updated (.+)$/ do |count, object_type|
  page.all("##{object_type.pluralize} .#{object_type.singularize}").length.should == count.to_i
end

Then /^the sprint named (.+) should have (\d+) impediments? named (.+)$/ do |sprint_name, count, impediment_subject|
  sprints = Sprint.find(:all, :conditions => { :name => sprint_name })
  sprints.length.should == 1

  sprints.first.impediments.map{ |i| i.subject==impediment_subject}.length.should == count.to_i
end

Then /^the impediment "(.+)" should signal( | un)successful saving$/ do |impediment_subject, negative|
  negative = !negative.blank?

  element = {}
  begin
    wait_until(5) do
      element = page.find(:xpath, "//div[contains(concat(' ',normalize-space(@class),' '),' impediment ') and contains(., '#{impediment_subject}')]")
      !element[:class].include?('saving') || element[:class].include?('error')
    end
  rescue Capybara::TimeoutError
    fail "The impediment '#{impediment_subject}' did not finish saving within within 5 sec"
  end

  if negative
    element[:class].should be_include('error')
  else
    element[:class].should_not be_include('error')
  end
end

Then /^the sprint should be updated accordingly$/ do
  sprint = Sprint.find(@sprint_params['id'])

  sprint.attributes.each_key do |key|
    unless ['updated_on', 'created_on'].include?(key)
      (key.include?('_date') ? sprint[key].strftime("%Y-%m-%d") : sprint[key]).should == @sprint_params[key]
    end
  end
end

Then /^the status of the story should be set as (.+)$/ do |status|
  @story.reload
  @story.status.name.downcase.should == status
end

Then /^the story named (.+) should have 1 task named (.+)$/ do |story_subject, task_subject|
  stories = Story.find(:all, :conditions => { :subject => story_subject })
  stories.length.should == 1

  tasks = Task.find(:all, :conditions => { :parent_id => stories.first.id, :subject => task_subject })
  tasks.length.should == 1
end

Then /^the story should be at the (top|bottom)$/ do |position|
  if position == 'top'
    story_position(@story).should == 1
  else
    story_position(@story).should == @story_ids.length
  end
end

Then /^the story should be at position (.+)$/ do |position|
  story_position(@story).should == position.to_i
end

Then /^the story should have a (.+) of (.+)$/ do |attribute, value|
  @story.reload
  if attribute=="tracker"
    attribute="tracker_id"
    value = Tracker.find(:first, :conditions => ["name=?", value]).id
  end
  @story[attribute].should == value
end

Then /^the wiki page (.+) should contain (.+)$/ do |title, content|
  title = Wiki.titleize(title)
  page = @project.wiki.find_page(title)
  page.should_not be_nil

  raise "\"#{content}\" not found on page \"#{title}\"" unless page.content.text.match(/#{content}/)
end

Then /^(issue|task|story) (.+) should have (.+) set to (.+)$/ do |type, subject, attribute, value|
  issue = Issue.find_by_subject(subject)
  issue[attribute].should == value.to_i
end

Then /^the error alert should show "(.+?)"$/ do |msg|
  Then %Q{I should see "#{msg}" within "#msgBox"}
end

Then /^the start date of "(.+?)" should be "(.+?)"$/ do |sprint_name, date|
  version = Version.find_by_name(sprint_name)

  Then %Q{I should see "#{date}" within "div#sprint_#{version.id} div.start_date"}
end

Then /^I should see "(.+?)" as a task to story "(.+?)"$/ do |task_name, story_name|
  story = Story.find_by_subject(story_name)

  Then %{I should see "#{task_name}" within "tr.story_#{story.id}"}
end

Then /^the (?:issue|task|story) "(.+?)" should have "(.+?)" as its target version$/ do |task_name, version_name|
  issue = Issue.find_by_subject(task_name)
  version = Version.find_by_name(version_name)

  issue.fixed_version.should eql version
end

Then /^there should not be a saving error on task "(.+?)"$/ do |task_name|
  elements = all(:xpath, "//*[contains(., \"#{task_name}\")]")
  task_div = elements.find{|e| e.tag_name == "div" && e[:class].include?("task")}
  task_div[:class].should_not include("error")
end

Then /^I should be notified that the issue "(.+?)" is an invalid parent to the issue "(.+?)" because of cross project limitations$/ do |parent_name, child_name|
  Then %Q{I should see "#{I18n.t(:field_parent_issue)} is invalid because the issue '#{child_name}' is a backlogs task and as such can not have the backlogs story '#{parent_name}' as it´s parent as long as the story is in a different project" within "#errorExplanation"}
end

Then /^"([^"]*)" should( not)? be an option for "([^"]*)"(?: within "([^\"]*)")?$/ do |value, negate, field, selector|
  scope = selector ? Nokogiri::CSS.xpath_for(selector).first : ""
  unless negate
    page.should have_xpath(scope  + "//select[@name='#{field}']/option[contains(.,'#{value}')]")
  else
    page.should_not have_xpath(scope  + "//select[@name='#{field}']/option[contains(.,'#{value}')]")
  end
end

Then /^I should( not)? see the status "([^"]*)" for "([^"]*)" within "([^"]*)"$/ do |negate, value, story_name, selector|
  story_id = Issue.find_by_subject(story_name).id
  selector = "#story_#{story_id} " + selector
  unless negate
    Then %Q{I should see "#{value}" within "#{selector}"}
  else
    Then %Q{I should not see "#{value}" within "#{selector}"}
  end
end
