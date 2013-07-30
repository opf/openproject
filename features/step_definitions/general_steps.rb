# encoding: utf-8

#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'active_record/fixtures'
require "rack_session_access/capybara"

Before do |scenario|
  unless ScenarioDisabler.empty_if_disabled(scenario)
    FactoryGirl.create(:admin) unless User.find_by_login("admin")
    FactoryGirl.create(:anonymous) unless AnonymousUser.count > 0
    Setting.notified_events = [] #can not test mailer

    if Capybara.current_driver.to_s.include?("selenium")
      Capybara.current_session.driver.browser.manage.window.resize_to(3000, 3000)
    end
  end
end

Given /^I am logged in$/ do
  @user = FactoryGirl.create :user
  page.set_rack_session(:user_id => @user.id)
end

When(/^I log out in the background$/) do
  page.execute_script("jQuery.ajax('/logout', {
    success: function () {
      jQuery(document.body).addClass('logout-ajax')
    }
  })")

  page.should have_selector("body.logout-ajax")
end

Given /^(?:|I )am not logged in$/ do
  User.current = AnonymousUser.first
end

Given /^(?:|I )am [aA]dmin$/ do
  FactoryGirl.create :admin unless User.where(:login => 'admin').any?
  FactoryGirl.create :anonymous unless AnonymousUser.count > 0
  login('admin', 'adminADMIN!')
end

Given /^I am already logged in as "(.+?)"$/ do |login|
  user = User.find_by_login(login)
  # see https://github.com/railsware/rack_session_access
  page.set_rack_session(:user_id => user.id)
end

Given /^(?:|I )am logged in as "([^\"]*)"$/ do |username|
  FactoryGirl.create :admin unless User.where(:login => 'admin').any?
  FactoryGirl.create :anonymous unless AnonymousUser.count > 0
  login(username, 'adminADMIN!')
end

Given /^(?:|I )am (not )?impaired$/ do |bool|
  (user = User.current).impaired = !bool
  user.save
end

Given /^there is 1 [pP]roject with(?: the following)?:$/ do |table|
  p = FactoryGirl.build(:project)
  send_table_to_object(p, table)
end

Then /^the project "([^"]*)" is( not)? public$/ do |project_name, negation|
  p = Project.find_by_name(project_name)
  p.update_attribute(:is_public, !negation)
end

Given /^the [Pp]roject "([^\"]*)" has 1 [wW]iki(?: )?[pP]age with the following:$/ do |project, table|
  p = Project.find_by_name(project)

  p.wiki.create! unless p.wiki

  page = FactoryGirl.create(:wiki_page, :wiki => p.wiki)
  content = FactoryGirl.create(:wiki_content, :page => page)

  send_table_to_object(page, table)
end

Given /^the plugin (.+) is loaded$/ do |plugin_name|
  plugin_name = plugin_name.gsub("\"", "")
  Redmine::Plugin.all.detect {|x| x.id == plugin_name.to_sym}.present? ? nil : pending("Plugin #{plugin_name} not loaded")
end

Given /^(?:the )?[pP]roject "([^\"]*)" uses the following [mM]odules:$/ do |project, table|
  p = Project.find_by_name(project)

  p.enabled_module_names += table.raw.map { |row| row.first }
  p.reload
end

Given /^(?:the )?[pP]roject "([^\"]*)" does not use the following [mM]odules:$/ do |project, table|
  p = Project.find_by_name(project)

  p.enabled_module_names -= table.raw.map { |row| row.first }
  p.reload
end

Given /^the [Uu]ser "([^\"]*)" is a "([^\"]*)" (?:in|of) the [Pp]roject "([^\"]*)"$/ do |user, role, project|
  u = User.find_by_login(user)
  r = Role.find_by_name(role)
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  as_admin do
    Member.new.tap do |m|
      m.user = u
      m.privacy_unnecessary = true if plugin_loaded?("redmine_dtag_privacy")
      m.roles << r
      m.project = p
    end.save!
  end
end

Given /^the [Uu]ser "([^\"]*)" has the following preferences$/ do |user, table|
  u = User.find_by_login(user)

  send_table_to_object(u.pref, table)
end


Given /^there is a(?:n)? (default )?(?:issue)?status with:$/ do |default, table|
  name = table.raw.select { |ary| ary.include? "name" }.first[table.raw.first.index("name") + 1].to_s
  IssueStatus.find_by_name(name) || IssueStatus.create(:name => name.to_s, :is_default => !!default)
end

Given /^there is a(?:n)? (default )?issuepriority with:$/ do |default, table|
  name = table.raw.select { |ary| ary.include? "name" }.first[table.raw.first.index("name") + 1].to_s
  project = get_project
  IssuePriority.new.tap do |prio|
    prio.name = name
    prio.is_default = !!default
    prio.project = project
    prio.save!
  end
end

Given /^there is a [rR]ole "([^\"]*)"$/ do |name|
  Role.spawn.tap { |r| r.name = name }.save! unless Role.find_by_name(name)
end

Given /^there are the following roles:$/ do |table|
  table.raw.flatten.each do |name|
    FactoryGirl.create(:role, :name => name) unless Role.find_by_name(name)
  end
end

Given /^the [rR]ole "([^\"]*)" may have the following [rR]ights:$/ do |role, table|
  r = Role.find_by_name(role)
  raise "No such role was defined: #{role}" unless r
  as_admin do
    available_perms = Redmine::AccessControl.permissions.collect(&:name)
    r.permissions = []

    table.raw.each do |_perm|
      perm = _perm.first
      unless perm.blank?
        perm = perm.gsub(" ", "_").underscore.to_sym
        if available_perms.include?(:"#{perm}")
          r.permissions << perm
        end
      end
    end

    r.save!
  end
end

Given /^the [rR]ole "(.+?)" has no (?:[Pp]ermissions|[Rr]ights)$/ do |role_name|
  role = Role.find_by_name(role_name)
  raise "No such role was defined: #{role_name}" unless role
  as_admin do
    role.permissions = []
    role.save!
  end
end

Given /^the [Uu]ser "([^\"]*)" has 1 time [eE]ntry$/ do |user|
  u = User.find_by_login user
  p = u.projects.last
  raise "This user must be member of a project to have issues" unless p
  i = Issue.generate_for_project!(p)
  t = TimeEntry.generate
  t.user = u
  t.issue = i
  t.project = p
  t.activity.project = p
  t.activity.save!
  t.save!
end

Given /^the [Uu]ser "([^\"]*)" has 1 time entry with (\d+\.?\d*) hours? at the project "([^\"]*)"$/ do |user, hours, project|
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  as_admin do
    t = TimeEntry.generate
    i = Issue.generate_for_project!(p)
    t.project = p
    t.issue = i
    t.hours = hours.to_f
    t.user = User.find_by_login user
    t.activity.project = p
    t.activity.save!
    t.save!
  end
end


Given /^the [Pp]roject "([^\"]*)" has (\d+) [tT]ime(?: )?[eE]ntr(?:ies|y) with the following:$/ do |project, count, table|
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  as_admin count do
    t = TimeEntry.generate
    i = Issue.generate_for_project!(p)
    t.project = p
    t.work_package = i
    t.activity.project = p
    t.activity.save!
    send_table_to_object(t, table,
      :user => Proc.new do |o,v|
        o.user = User.find_by_login(v)
        o.save!
      end,
      :spent_on => Proc.new do |object, value|
        # This works for definitions like "2 years ago"
        number, time_unit, tempus = value.split
        time = number.to_i.send(time_unit.to_sym).send(tempus.to_sym)
        object.spent_on = time
        object.save!
      end
    )
  end
end

Given /^the [Pp]roject "([^\"]*)" has (\d+) [Dd]ocument with(?: the following)?:$/ do |project, count, table|
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  as_admin count do
    d = Document.spawn
    d.project = p
    d.category = DocumentCategory.first
    d.save!
    send_table_to_object(d, table)
  end
end

Given /^the [Pp]roject (.+) has 1 version with(?: the following)?:$/ do |project, table|
  project.gsub!("\"", "")
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  table.rows_hash["effective_date"] = eval(table.rows_hash["effective_date"]).to_date if table.rows_hash["effective_date"]

  as_admin do
    v = Version.generate
    send_table_to_object(v, table)
    p.versions << v
  end
end

Given /^the [pP]roject "([^\"]*)" has 1 [sS]ubproject$/ do |project|
  parent = Project.find_by_name(project)
  p = Project.generate
  p.set_parent!(parent)
  p.save!
end

Given /^the [pP]roject "([^\"]*)" has 1 [sS]ubproject with the following:$/ do |project, table|
  parent = Project.find_by_name(project)
  p = FactoryGirl.build(:project)
  as_admin do
    send_table_to_object(p, table)
  end

  p.set_parent!(parent)
  p.save!
end

Given /^there are the following types:$/ do |table|
  table.map_headers! { |header| header.underscore.gsub(' ', '_') }
  table.hashes.each_with_index do |t, i|
    type = Type.find_by_name(t['name'])
    type = Type.new :name => t['name'] if type.nil?
    type.position       = t['position'] ? t['position'] : i
    type.is_in_roadmap  = t['is_in_roadmap'] ? t['is_in_roadmap'] : true
    type.is_milestone   = t['is_milestone'] ? t['is_milestone'] : true
    type.is_default     = t['is_default'] ? t['is_default'] : false
    type.in_aggregation = t['in_aggregation'] ? t['in_aggregation'] : true
    type.save!
  end
end

Given /^there are the following issue status:$/ do |table|

  table.hashes.each_with_index do |t, i|
    status = IssueStatus.find_by_name(t['name'])
    status = IssueStatus.new :name => t['name'] if status.nil?
    status.is_closed = t['is_closed'] == 'true' ? true : false
    status.is_default = t['is_default'] == 'true' ? true : false
    status.position = t['position'] ? t['position'] : i
    status.default_done_ratio = t['default_done_ratio']
    status.save!
  end
end

Given /^the type "(.+?)" has the default workflow for the role "(.+?)"$/ do |type_name, role_name|
  role = Role.find_by_name(role_name)
  type = Type.find_by_name(type_name)
  type.workflows = []

  IssueStatus.all(:order => "id ASC").collect(&:id).combination(2).each do |c|
    type.workflows.build(:old_status_id => c[0], :new_status_id => c[1], :role => role)
  end
  type.save!
end


Given /^the [iI]ssue "([^\"]*)" has (\d+) [tT]ime(?: )?[eE]ntr(?:ies|y) with the following:$/ do |issue, count, table|
  i = Issue.find(:last, :conditions => ["subject = '#{issue}'"])
  raise "No such issue: #{issue}" unless i
  as_admin count do
    t = TimeEntry.generate
    t.project = i.project
    t.spent_on = DateTime.now
    t.work_package = i
    send_table_to_object(t, table,
      {:user => Proc.new do |o,v|
        o.user = User.find_by_login(v)
        o.save!
      end})
  end
end

Given /^I select to see [cC]olumn "([^\"]*)"$/ do |column_name|
  steps %Q{
    When I select \"#{column_name}\" from \"available_columns\"
    When I press \"→\"
  }
end

Given /^I select to see [cC]olumn(?:s)?$/ do |table|
  params = "?set_filter=1&" + table.raw.collect(&:first).collect do |name|
    page.source =~ /<option value="(.*?)">#{name}<\/option>/
    column_name = $1 || name.gsub(" ", "_").downcase
    "query[column_names][]=#{column_name}"
  end.join("&")
  visit(current_path + params)
end

Given /^I start debugging$/ do
  save_and_open_page
  require 'pry'
  binding.pry
  true
end

Given /^I (?:stop|pause) (?:step )?execution$/ do
  loop do
    $stdout.puts "\nPausing step execution. Press <Enter> to continue. Enter `debug` to start debugging."
    text = $stdin.readline

    step "I start debugging" if text =~ /debug/

    break if text.strip.empty?
  end
end

When /^(?:|I )login as (.+?)(?: with password (.+))?$/ do |username, password|
  username = username.gsub("\"", "")
  password = password.nil? ? "adminADMIN!" : password.gsub("\"", "")
  login(username, password)
end

When "I logout" do
  visit "/logout"
end

Then /^I should be logged in as "([^\"]*)"?$/ do |username|
  user = User.find_by_login(username) || User.anonymous
  page.should have_xpath("//div[contains(., 'Logged in as #{username}')] | //a[contains(.,'#{user.name}')]")

  User.current = user
end

Then "I should be logged out" do
  page.should have_css("a.login")
end

When /^I satisfy the "(.+)" plugin to (.+)$/ do |plugin_name, action|
  if plugin_loaded?(plugin_name)
    action_name = action.gsub("\"", "")

    plugin_action(plugin_name, action_name)
  end
end

Given /^I am working in [pP]roject "(.+?)"$/ do |project_name|
  @project = Project.find_by_name(project_name)
end

Given /^the [pP]roject uses the following modules:$/ do |table|
  step %Q{the project "#{get_project}" uses the following modules:}, table
end


Given /^the user "(.*?)" is a "([^\"]*?)"$/ do |user, role|
  step %Q{the user "#{user}" is a "#{role}" in the project "#{get_project.name}"}
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following types:$/ do |project_name, table|
  p = get_project(project_name)
  table.hashes.each_with_index do |t, i|
    type = Type.find_by_name(t['name'])
    type = Type.new :name => t['name'] if type.nil?
    type.position = t['position'] ? t['position'] : i
    type.is_in_roadmap = t['is_in_roadmap'] ? t['is_in_roadmap'] : true
    type.save!
    if !p.types.include?(type)
      p.types << type
      p.save!
    end
  end
end

When(/^I wait for "(.*?)" minutes$/) do |number_of_minutes|
 page.set_rack_session(updated_at: Time.now - number_of_minutes.to_i.minutes)
end

def get_project(project_name = nil)
  if project_name.blank?
    project = @project
  else
    project = Project.find_by_name(project_name)
  end
  if project.nil?
    if project_name.blank?
      raise "Could not identify the current project. Make sure to use the 'I am working in project \"Project Name\" step beforehand."
    else
      raise "Could not find project with the name \"#{project_name}\"."
    end
  end
  project
end


# Modify a given user using the specified table
def modify_user(u, table)
  as_admin do
    send_table_to_object(u, table,
      :default_rate => Proc.new do |user, value|
        user.save!
        DefaultHourlyRate.new.tap do |r|
          r.valid_from = 3.years.ago.to_date
          r.rate       = value
          r.user_id    = user.id
        end.save!
      end,
      :name => Proc.new {|user, value| user.login = name; user.save!},
      :hourly_rate => Proc.new do |user, value|
        user.save!
        HourlyRate.new.tap do |r|
          r.valid_from = (2.years.ago + HourlyRate.count.days).to_date
          r.rate       = value
          r.user_id    = user.id
          r.project    = user.projects.last
        end.save!
      end
    )

    u.save!
  end
  u
end

# Encapsule the logic to set a custom field on an issue
def add_custom_value_to_issue(object, key, value)
  if WorkPackageCustomField.all.collect(&:name).include? key.to_s
    cv = CustomValue.find(:first, :conditions => ["customized_id = '#{object.id}'"])
    cv ||= CustomValue.new
    cv.customized_type = "WorkPackage"
    cv.customized_id = object.id
    cv.custom_field_id = WorkPackageCustomField.first(:joins => :translations, :conditions => ["custom_field_translations.name = ?", key]).id
    cv.value = value
    cv.save!
  end
end

# Try to assign an object the values set in a table
def send_table_to_object(object, table, except = {}, rescue_block = nil)
  return unless table.raw.present?
  as_admin do
    table.rows_hash.each do |key, value|
      _key = key.gsub(" ", "_").underscore.to_sym
      if except[_key]
        except[_key].call(object, value)
      elsif except[key]
        except[key].call(object, value)
      elsif object.respond_to? :"#{_key}="
        object.send(:"#{_key}=", value)
      elsif rescue_block
        rescue_block.call(object, key, value)
      else
        raise "No such method #{_key} on a #{object.class}"
      end
    end
    object.save! if object.changed?
  end
end

# Do something as admin
def as_admin(count = 1)
  cur_user = User.current
  User.current = User.find_by_login("admin")
  retval = nil
  count.to_i.times do
    retval = yield
  end
  User.current = cur_user
  retval
end

def plugin_loaded?(name)
  Redmine::Plugin.all.detect {|x| x.id == name.to_sym}.present?
end

