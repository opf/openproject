Given /^I am logged out$/ do
  logout
end

Given /^I set the (.+) of the story to (.+)$/ do |attribute, value|
  if attribute == "tracker"
    attribute = "tracker_id"
    value = Tracker.find(:first, :conditions => ["name=?", value]).id
  elsif attribute == "status"
    attribute = "status_id"
    value = IssueStatus.find(:first, :conditions => ["name=?", value]).id
  elsif %w[backlog sprint].include? attribute
    attribute = 'fixed_version_id'
    value = Version.find_by_name(value).id
  end
  @story_params[attribute] = value
end

Given /^I set the (.+) of the task to (.+)$/ do |attribute, value|
  value = '' if value == 'an empty string'
  @task_params[attribute] = value
end

Given /^I want to create a story(?: in [pP]roject "(.+?)")?$/ do |project_name|
  project = get_project(project_name)
  @story_params = initialize_story_params(project)
end

Given /^I want to create a task for (.+)(?: in [pP]roject "(.+?)")?$/ do |story_subject, project_name|
  project = get_project(project_name)

  story = Story.find(:first, :conditions => ["subject=?", story_subject])
  @task_params = initialize_task_params(project, story)
end

Given /^I want to create an impediment for (.+?)(?: in [pP]roject "(.+?)")?$/ do |sprint_subject, project_name|
  project = get_project(project_name)
  sprint = Sprint.find(:first, :conditions => { :name => sprint_subject })
  @impediment_params = initialize_impediment_params(project, sprint.id)
end

Given /^I want to edit the task named (.+)$/ do |task_subject|
  task = Task.find(:first, :conditions => { :subject => task_subject })
  task.should_not be_nil
  @task_params = HashWithIndifferentAccess.new(task.attributes)
end

Given /^I want to edit the impediment named (.+)$/ do |impediment_subject|
  impediment = Task.find(:first, :conditions => { :subject => impediment_subject })
  impediment.should_not be_nil
  @impediment_params = HashWithIndifferentAccess.new(impediment.attributes)
end

Given /^I want to edit the sprint named (.+)$/ do |name|
  sprint = Sprint.find(:first, :conditions => ["name=?", name])
  sprint.should_not be_nil
  @sprint_params = HashWithIndifferentAccess.new(sprint.attributes)
end

Given /^I want to indicate that the impediment blocks (.+)$/ do |blocks_csv|
  blocks_csv = Story.find(:all, :conditions => { :subject => blocks_csv.split(', ') }).map{ |s| s.id }.join(',')
  @impediment_params[:blocks] = blocks_csv
end

Given /^I want to set the (.+) of the sprint to (.+)$/ do |attribute, value|
  value = '' if value == "an empty string"
  @sprint_params[attribute] = value
end

Given /^I want to set the (.+) of the impediment to (.+)$/ do |attribute, value|
  value = '' if value == "an empty string"
  @impediment_params[attribute] = value
end

Given /^I want to edit the story with subject (.+)$/ do |subject|
  @story = Story.find(:first, :conditions => ["subject=?", subject])
  @story.should_not be_nil
  @story_params = HashWithIndifferentAccess.new(@story.attributes)
end

Given /^the backlogs module is initialized(?: in [pP]roject "(.*)")?$/ do |project_name|
  project = get_project(project_name)

  Given 'the following trackers are configured to track stories:', Cucumber::Ast::Table.new([['Story'], ['Epic']])
  Given 'the tracker "Task" is configured to track tasks'
  Given "the project \"#{project.name}\" uses the following trackers:", Cucumber::Ast::Table.new([['Story', 'Task']])
end

Given /^the [pP]roject(?: "([^\"]+?)")? uses the following trackers:$/ do |project, table|
  project = get_project(project)

  trackers = table.raw.map do |line|
    name = line.first
    tracker = Tracker.find_by_name(name)

    tracker = Factory.create(:tracker, :name => name) if tracker.blank?
    tracker
  end

  project.update_attributes :tracker_ids => trackers.map(&:id).map(&:to_s)
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following sprints:$/ do |project_name, table|
  project = get_project(project_name)

  table.hashes.each do |version|
    version['project_id'] = project.id
    ['effective_date', 'start_date'].each do |date_attr|
      version[date_attr] = eval(version[date_attr]).strftime("%Y-%m-%d") if version[date_attr].match(/^(\d+)\.(year|month|week|day|hour|minute|second)(s?)\.(ago|from_now)$/)
    end
    sprint = Sprint.create! version

    vs = sprint.version_settings.build
    vs.project = project
    vs.display_left!
    vs.save!
  end
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following (?:product )?(?:owner )?backlogs?:$/ do |project_name, table|
  project = get_project(project_name)

  table.raw.each do |row|
    version = Version.create!(:project_id => project, :name => row.first)

    vs = version.version_settings.build
    vs.project = project
    vs.display_right!
    vs.save!
  end
end

Given /^the [pP]roject(?: "(.+?)")? has the following stories in the following (?:product )?(?:owner )?backlogs:$/ do |project_name, table|
  if project_name
    Given %Q{the project "#{project_name}" has the following stories in the following sprints:}, table
  else
    Given "the project has the following stories in the following sprints:", table
  end
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following stories in the following sprints:$/ do |project_name, table|
  project = get_project(project_name)

  project.issues.delete_all
  prev_id = ''

  table.hashes.each do |story|
    params = initialize_story_params(project)
    params['parent'] = Issue.find_by_subject(story['parent'])
    params['subject'] = story['subject']
    params['prev_id'] = prev_id
    params['fixed_version_id'] = Version.find_by_name(story['sprint'] || story['backlog']).id
    params['story_points'] = story['story_points']

    # NOTE: We're bypassing the controller here because we're just
    # setting up the database for the actual tests. The actual tests,
    # however, should NOT bypass the controller
    begin
      s = Story.create_and_position params
    rescue
      debugger
      true
    end
    prev_id = s.id
  end
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following tasks:$/ do |project_name, table|
  project = get_project(project_name)

  User.current = User.find(:first)

  table.hashes.each do |task|
    story = Story.find(:first, :conditions => { :subject => task['parent'] })
    params = initialize_task_params(project, story)
    params['subject'] = task['subject']

    # NOTE: We're bypassing the controller here because we're just
    # setting up the database for the actual tests. The actual tests,
    # however, should NOT bypass the controller
    Task.create_with_relationships(params, project.id)
  end
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following issues:$/ do |project_name, table|
  project = get_project(project_name)

  User.current = User.find(:first)

  table.hashes.each do |task|
    parent = Issue.find(:first, :conditions => { :subject => task['parent'] })
    tracker = Tracker.find_by_name(task['tracker'])
    params = initialize_issue_params(project, tracker, parent)
    params['subject'] = task['subject']
    version = Version.find_by_name(task['sprint'] || task['backlog'])
    params['fixed_version_id'] = version.id if version

    # NOTE: We're bypassing the controller here because we're just
    # setting up the database for the actual tests. The actual tests,
    # however, should NOT bypass the controller
    begin
      Issue.create!(params)
    rescue
      debugger
      raise
    end
  end
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following impediments:$/ do |project_name, table|
  project = get_project(project_name)

  User.current = User.find(:first)

  table.hashes.each do |impediment|
    sprint = Sprint.find(:first, :conditions => { :name => impediment['sprint'] })
    blocks = Story.find(:all, :conditions => { :subject => impediment['blocks'].split(', ')  }).map{ |s| s.id }
    params = initialize_impediment_params(project, sprint)
    params['subject'] = impediment['subject']
    params['blocks_ids']  = blocks.join(',')

    # NOTE: We're bypassing the controller here because we're just
    # setting up the database for the actual tests. The actual tests,
    # however, should NOT bypass the controller
    Impediment.create_with_relationships(params, project.id)
  end
end


Given /^the [pP]roject(?: "([^\"]*)")? has the following trackers:$/ do |project_name, table|
  p = get_project(project_name)
  table.hashes.each_with_index do |t, i|
    tracker = Tracker.find_by_name(t['name'])
    tracker = Tracker.new :name => t['name'] if tracker.nil?
    tracker.position = t['position'] ? t['position'] : i
    tracker.is_in_roadmap = t['is_in_roadmap'] ? t['is_in_roadmap'] : true
    tracker.save!
    p.trackers << tracker
    p.save!
  end
end

Given /^the [pP]roject uses the following modules:$/ do |table|
  Given %Q{the project "#{get_project}" uses the following modules:}, table
end


Given /the user "(.*?)" is a "(.*?)"/ do |user, role|
  Given %Q{the user "#{user}" is a "#{role}" in the project "#{get_project.name}"}
end

Given /^I have selected card label stock (.+)$/ do |stock|
  Setting.plugin_redmine_backlogs[:card_spec] = stock

  # If this goes wrong, you are probably missing
  #   vendor/plugins/redmine_backlogs/config/labels.yml
  # Run
  #   rake redmine:backlogs:default_labels
  # to get the ones, shipped with the plugin or
  #   rake redmine:backlogs:current_labels
  # to get current one, downloaded from the internetz.
  Cards::TaskboardCards.should be_available
end

Given /^I have set my API access key$/ do
  Setting[:rest_api_enabled] = 1
  User.current.reload
  User.current.api_key.should_not be_nil
  @api_key = User.current.api_key
end

Given /^I have guessed an API access key$/ do
  Setting[:rest_api_enabled] = 1
  @api_key = 'guess'
end

Given /^I have set the content for wiki page (.+) to (.+)$/ do |title, content|
  title = Wiki.titleize(title)
  page = @project.wiki.find_page(title)
  if ! page
    page = WikiPage.new(:wiki => @project.wiki, :title => title)
    page.content = WikiContent.new
    page.save
  end

  page.content.text = content
  page.save.should be_true
end

Given /^I have made (.+) the template page for sprint notes/ do |title|
  Setting.plugin_redmine_backlogs = Setting.plugin_redmine_backlogs.merge({:wiki_template => Wiki.titleize(title)})
end

Given /^there are no stories in the [pP]roject$/ do
  @project.issues.delete_all
end

Given /^I am working in [pP]roject "(.+?)"$/ do |project_name|
  @project = Project.find_by_name(project_name)
end

Given /^the scrum statistics are disabled$/ do
  Setting.plugin_redmine_backlogs = Setting.plugin_redmine_backlogs.merge(:show_statistics => false)
end

Given /^the scrum statistics are enabled$/ do
  Setting.plugin_redmine_backlogs = Setting.plugin_redmine_backlogs.merge(:show_statistics => true)
end

Given /^the tracker "(.+?)" is configured to track tasks$/ do |tracker_name|
  tracker = Tracker.find_by_name(tracker_name)
  tracker = Factory.create(:tracker, :name => tracker_name) if tracker.blank?

  Setting.plugin_redmine_backlogs = Setting.plugin_redmine_backlogs.merge(:task_tracker => tracker.id)
end

Given /^the following trackers are configured to track stories:$/ do |table|
  story_trackers = []
  table.raw.each do |line|
    name = line.first
    tracker = Tracker.find_by_name(name)

    tracker = Factory.create(:tracker, :name => name) if tracker.blank?
    story_trackers << tracker
  end

  Setting.plugin_redmine_backlogs = Setting.plugin_redmine_backlogs.merge(:story_trackers => story_trackers.map(&:id))
end
