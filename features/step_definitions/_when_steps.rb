When /^I create the impediment$/ do
  page.driver.post url_for(:controller => '/rb_impediments', :action => :create),
                   @impediment_params
end

When /^I create the story$/ do
  page.driver.post url_for(:controller => '/rb_stories', :action => :create),
                   @story_params
end

When /^I create the task$/ do
  page.driver.post url_for(:controller => '/rb_tasks', :action => :create),
                   @task_params
end

When /^I move the (story|item|task) named (.+) below (.+)$/ do |type, story_subject, prev_subject|
  work_package_class, controller_name =
    if type.strip == "task" then [Task, "rb_tasks"] else [Story, "rb_stories"] end
  story = work_package_class.find(:first, :conditions => ["subject=?", story_subject.strip])
  prev  = work_package_class.find(:first, :conditions => ["subject=?", prev_subject.strip])

  attributes = story.attributes
  attributes[:prev]             = prev.id
  attributes[:fixed_version_id] = prev.fixed_version_id unless type == "task"

  page.driver.post url_for(:controller => '/'+controller_name, :action => "update", :id => story),
                   attributes.merge({ "_method" => "put" })
end

When /^I move the story named (.+) (up|down) to the (\d+)(?:st|nd|rd|th) position of the sprint named (.+)$/ do |story_subject, direction, position, sprint_name|
  position = position.to_i
  story = Story.find(:first, :conditions => ["subject=?", story_subject])
  sprint = Sprint.find(:first, :conditions => ["name=?", sprint_name])
  story.fixed_version = sprint

  attributes = story.attributes
  attributes[:prev] = if position == 1
                        ''
                      else
                        stories = Story.find(:all, :conditions => ["fixed_version_id=? AND type_id IN (?)", sprint.id, Story.types], :order => "position ASC")
                        raise "You indicated an invalid position (#{position}) in a sprint with #{stories.length} stories" if 0 > position or position > stories.length
                        stories[position - (direction=="up" ? 2 : 1)].id
                      end

  page.driver.post url_for(:controller => '/rb_stories', :action => "update", :id => story.id),
                   attributes.merge({ "_method" => "put" })
end

When /^I move the (\d+)(?:st|nd|rd|th) story to the (\d+|last)(?:st|nd|rd|th)? position$/ do |old_pos, new_pos|
  @story_ids = page.all(:css, "#owner_backlogs_container .stories .story .id")

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

  page.driver.post url_for(:controller => '/rb_stories', :action => :update, :id => story.text),
                   {:prev => (prev.nil? ? '' : prev.text), :project_id => @project.id, "_method" => "put"}

  @story = Story.find(story.text.to_i)
end

When /^I request the server_variables resource$/ do
  visit url_for(:controller => '/rb_server_variables', :action => :show, :project_id => @project)
end

When /^I update the impediment$/ do
  page.driver.post url_for(:controller => '/rb_impediments', :action => :update),
                   @impediment_params.merge({ "_method" => "put" })
end

When /^I update the sprint$/ do
  page.driver.post url_for(:controller => '/rb_sprints', :action => "update", :sprint_id => @sprint_params['id']),
                   @sprint_params.merge({ "_method" => "put" })
end

When /^I update the story$/ do
  page.driver.post url_for(:controller => '/rb_stories', :action => :update, :id => @story_params[:id]),
                   @story_params.merge({ "_method" => "put" })
end

When /^I update the task$/ do
  page.driver.post url_for(:controller => '/rb_tasks', :action => :update, :id => @task_params[:id]),
                   @task_params.merge({ "_method" => "put" })
end

When /^I view the master backlog$/ do
  visit url_for(:controller => '/projects', :action => :show, :id => @project)
  click_link("Backlogs")
end

When /^I view the stories of (.+) in the work_packages tab/ do |sprint_name|
  sprint = Sprint.find(:first, :conditions => ["name=?", sprint_name])
  visit url_for(:controller => '/rb_queries', :action => :show, :project_id => sprint.project, :sprint_id => sprint)
end

When /^I view the stories in the work_packages tab/ do
  visit url_for(:controller => '/rb_queries', :action => :show, :project_id => @project)
end

# WARN: Depends on deprecated behavior of path_for('the task board for
#       "sprint name"')
When /^I view the sprint notes$/ do
  visit url_for(:controller => '/rb_wikis', :action => 'show', :sprint_id => @sprint)
end

# WARN: Depends on deprecated behavior of path_for('the task board for
#       "sprint name"')
When /^I edit the sprint notes$/ do
  visit url_for(:controller => '/rb_wikis', :action => 'edit', :sprint_id => @sprint)
end

When /^I follow "(.+?)" of the "(.+?)" (?:backlogs )?menu$/ do |link, backlog_name|
  sprint = Sprint.find_by_name(backlog_name)
  step %Q{I follow "#{link}" within "#backlog_#{sprint.id} .menu"}
end

When /^I open the "(.+?)" (?:backlogs )?menu/ do |backlog_name|
  sprint = Sprint.find_by_name(backlog_name)
  step %Q{I hover over "#backlog_#{sprint.id} .menu"}
end

When /^I close the "(.+?)" (?:backlogs )?menu/ do |backlog_name|
  sprint = Sprint.find_by_name(backlog_name)
  step %Q{I stop hovering over "#backlog_#{sprint.id} .menu"}
end

When /^I click on the text "(.+?)"$/ do |locator|
  find(:xpath, %Q{//*[contains(text(), "#{locator}")]}).click
end

When /^I click on the element with class "([^"]+?)"$/ do |locator|
  find(:css, ".#{locator}").click
end

When /^I confirm the story form$/ do
  find(:xpath, XPath::HTML.fillable_field("subject")).native.send_key :return
  step 'I wait for AJAX requests to finish'
  step 'I should not see ".saving"'
end

When /^I fill in the ids of the (tasks|work_packages|stories) "(.+?)" for "(.+?)"$/ do |model_name, subjects, field|
  model = Kernel.const_get(model_name.classify)
  ids = subjects.split(/,/).collect { |subject| model.find_by_subject(subject).id }

  step %{I fill in "#{ids.join(", ")}" for "#{field}"}
end

When /^I click on the impediment called "(.+?)"$/ do |impediment_name|
  step %Q{I click on the text "#{impediment_name}"}
end

When /^I click to add a new task for story "(.+?)"$/ do |story_name|
  story = Story.find_by_subject(story_name)

  page.all(:css, "tr.story_#{story.id} td.add_new").last.click
end

When /^I fill in the id of the work_package "(.+?)" as the parent work_package$/ do |work_package_name|
  work_package = WorkPackage.find_by_subject(work_package_name)

  # TODO: Simplify once the work_package#edit/update action is implemented
  find('#work_package_parent_id, #work_package_parent_id', visible: false).set(work_package.id)
end

When /^the request on task "(.+?)" is finished$/ do |task_name|
  # Wait for the modal link of this task to appear...
  elements = page.find(:xpath, "//div[contains(., '#{task_name}') and contains(@class,'task')]/descendant::a[contains(@href, .)]")
  # ...by selecting the task board card for a specific task and then go for the
  # link with the id only appearing after the task was saved
end

When /^I follow the link to add a subtask$/ do
  begin
    # new layout
    step 'I follow "Add subtask"'
  rescue Capybara::ElementNotFound
    # old layout
    step 'I follow "Add" within "#work_package_tree"'
  end
end

When /^I change the fold state of a version$/ do
  find(".backlog .toggler").click
end
