#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'active_record/fixtures'
require 'rack_session_access/capybara'

Before do |scenario|
  unless ScenarioDisabler.empty_if_disabled(scenario)
    FactoryGirl.create(:admin) unless User.find_by_login('admin')
    FactoryGirl.create(:anonymous) unless AnonymousUser.count > 0
    Setting.notified_events = [] # can not test mailer

    if Capybara.current_driver.to_s.include?('selenium')
      Capybara.current_session.driver.browser.manage.window.resize_to(3000, 3000)
    end
  end
end

Given /^I am logged in$/ do
  @user = FactoryGirl.create :user
  page.set_rack_session(user_id: @user.id)
end

When(/^I log out in the background$/) do
  page.execute_script("jQuery.ajax('/logout', {
    success: function () {
      jQuery(document.body).addClass('logout-ajax')
    }
  })")

  page.should have_selector('body.logout-ajax')
end

Given /^(?:|I )am not logged in$/ do
  User.current = AnonymousUser.first
end

Given /^(?:|I )am [aA]dmin$/ do
  admin = User.find_by_admin(true)

  login(admin.login, 'adminADMIN!')
end

Given /^(?:|I )am already [aA]dmin$/ do
  admin = User.find_by_admin(true)
  # see https://github.com/railsware/rack_session_access
  page.set_rack_session(user_id: admin.id)
end

Given /^I am already logged in as "(.+?)"$/ do |login|
  user = User.find_by_login(login)
  # see https://github.com/railsware/rack_session_access
  page.set_rack_session(user_id: user.id)
end

Given /^(?:|I )am logged in as "([^\"]*)"$/ do |username|

  login(username, 'adminADMIN!')
end

Given /^(?:|I )am (not )?impaired$/ do |bool|
  (user = User.current).impaired = !bool
  user.save
end

Given /^there is 1 [pP]roject with(?: the following)?:$/ do |table|
  standard_type = FactoryGirl.build(:type_standard)
  p = FactoryGirl.build(:project)

  p.types << standard_type

  send_table_to_object(p, table)
end

Then /^the project "([^"]*)" is( not)? public$/ do |project_name, negation|
  p = Project.find_by_name(project_name)
  p.update_attribute(:is_public, !negation)
end

Given /^the plugin (.+) is loaded$/ do |plugin_name|
  plugin_name = plugin_name.gsub("\"", '')
  Redmine::Plugin.all.detect { |x| x.id == plugin_name.to_sym }.present? ? nil : pending("Plugin #{plugin_name} not loaded")
end

Given /^(?:the )?[pP]roject "([^\"]*)" uses the following [mM]odules:$/ do |project, table|
  p = Project.find_by_name(project)

  p.enabled_module_names += table.raw.map(&:first)
  p.reload
end

Given /^(?:the )?[pP]roject "([^\"]*)" does not use the following [mM]odules:$/ do |project, table|
  p = Project.find_by_name(project)

  p.enabled_module_names -= table.raw.map(&:first)
  p.reload
end

Given /^the [Uu]ser "([^\"]*)" has 1 time [eE]ntry$/ do |user|
  u = User.find_by_login user
  p = u.projects.last
  raise 'This user must be member of a project to have issues' unless p
  i = FactoryGirl.create(:work_package, project: p)
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
    i = FactoryGirl.create(:work_package, project: p)
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
    i = FactoryGirl.create(:work_package, project: p)
    t.project = p
    t.work_package = i
    t.activity.project = p
    t.activity.save!
    send_table_to_object(t, table,
                         user: Proc.new do |o, v|
                           o.user = User.find_by_login(v)
                           o.save!
                         end,
                         spent_on: Proc.new do |object, value|
                           # This works for definitions like "2 years ago"
                           number, time_unit, tempus = value.split
                           time = number.to_i.send(time_unit.to_sym).send(tempus.to_sym)
                           object.spent_on = time
                           object.save!
                         end
    )
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
  table = table.map_headers { |header| header.underscore.gsub(' ', '_') }
  table.hashes.each_with_index do |t, i|
    type = Type.find_by_name(t['name'])
    type = Type.new name: t['name'] if type.nil?
    type.position       = t['position'] ? t['position'] : i
    type.is_in_roadmap  = t['is_in_roadmap'] ? t['is_in_roadmap'] : true
    type.is_milestone   = t['is_milestone'] ? t['is_milestone'] : true
    type.is_default     = t['is_default'] ? t['is_default'] : false
    type.in_aggregation = t['in_aggregation'] ? t['in_aggregation'] : true
    type.is_standard    = t['is_standard'] ? t['is_standard'] : false
    type.save!
  end
end

Given /^there are the following issue status:$/ do |table|

  table.hashes.each_with_index do |t, i|
    status = Status.find_by_name(t['name'])
    status = Status.new name: t['name'] if status.nil?
    status.is_closed = t['is_closed'] == 'true'
    status.is_default = t['is_default'] == 'true'
    status.position = t['position'] ? t['position'] : i
    status.default_done_ratio = t['default_done_ratio']
    status.save!
  end
end

Given /^the type "(.+?)" has the default workflow for the role "(.+?)"$/ do |type_name, role_name|
  role = Role.find_by_name(role_name)
  type = Type.find_by_name(type_name)
  type.workflows = []

  Status.all(order: 'id ASC').map(&:id).combination(2).each do |c|
    type.workflows.build(old_status_id: c[0], new_status_id: c[1], role: role)
  end
  type.save!
end

Given /^the [iI]ssue "([^\"]*)" has (\d+) [tT]ime(?: )?[eE]ntr(?:ies|y) with the following:$/ do |issue, count, table|
  i = WorkPackage.find(:last, conditions: ["subject = '#{issue}'"])
  raise "No such issue: #{issue}" unless i
  as_admin count do
    t = TimeEntry.generate
    t.project = i.project
    t.spent_on = DateTime.now
    t.work_package = i
    send_table_to_object(t, table,
                         user: Proc.new do |o, v|
                           o.user = User.find_by_login(v)
                           o.save!
                         end)
  end
end

Given /^I select to see [cC]olumn "([^\"]*)"$/ do |column_name|
  within('.ng-modal-inner') do
    find('input.select2-input').click
  end

  s2_result = find('ul.select2-result-single li', text: column_name)
  s2_result.click
end

Given /^I select to not see [cC]olumn "([^\"]*)"$/ do |_column_name|
  pending
end

Given /^I select to see [cC]olumn(?:s)?$/ do |table|
  result = []
  table.raw.each do |_perm|
    perm = _perm.first
    unless perm.blank?
      result.push(perm)
    end
  end

  result.each do |column_name|
    within('.ng-modal-inner') do
      find('input.select2-input').click
    end

    s2_result = find('ul.select2-result-single li', text: column_name)
    s2_result.click
  end
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

    step 'I start debugging' if text =~ /debug/

    break if text.strip.empty?
  end
end

When /^(?:|I )login as (.+?)(?: with password (.+))?$/ do |username, password|
  username = username.gsub("\"", '')
  password = password.nil? ? 'adminADMIN!' : password.gsub("\"", '')
  login(username, password)
end

When /^(?:|I )login with autologin enabled as (.+?)(?: with password (.+))?$/ do |username, password|
  username = username.gsub("\"", '')
  password = password.nil? ? 'adminADMIN!' : password.gsub("\"", '')
  page.driver.post signin_path(username: username, password: password, autologin: 1)
end

When 'I logout' do
  visit '/logout'
end

Then /^I should be logged in as "([^\"]*)"?$/ do |username|
  user = User.find_by_login(username) || User.anonymous
  page.should have_xpath("//div[contains(., 'Logged in as #{username}')] | //a[contains(.,'#{user.name}')]")

  User.current = user
end

Then 'I should be logged out' do
  page.should have_css('a.login')
end

When /^I satisfy the "(.+)" plugin to (.+)$/ do |plugin_name, action|
  if plugin_loaded?(plugin_name)
    action_name = action.gsub("\"", '')

    plugin_action(plugin_name, action_name)
  end
end

Given /^I am working in [pP]roject "(.+?)"$/ do |project_name|
  @project = Project.find_by_name(project_name)
end

Given /^the [pP]roject uses the following modules:$/ do |table|
  step %{the project "#{get_project}" uses the following modules:}, table
end

Given(/^the user "(.*?)" is responsible$/) do |user|
  project = get_project
  project.responsible_id = User.find_by_login(user).id
  project.save
end

Given /^the [pP]roject(?: "([^\"]*)")? has the following types:$/ do |project_name, table|
  p = get_project(project_name)
  table.hashes.each_with_index do |t, i|
    type = Type.find_by_name(t['name'])
    type = Type.new name: t['name'] if type.nil?
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
                         default_rate: Proc.new do |user, value|
                           user.save!
                           DefaultHourlyRate.new.tap do |r|
                             r.valid_from = 3.years.ago.to_date
                             r.rate       = value
                             r.user_id    = user.id
                           end.save!
                         end,
                         name: Proc.new { |user, _value| user.login = name; user.save! },
                         hourly_rate: Proc.new do |user, value|
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

# Encapsulate the logic to set a custom field on an issue
def add_custom_value_to_issue(object, key, value)
  if WorkPackageCustomField.all.map(&:name).include? key.to_s
    cv = CustomValue.find(:first, conditions: ["customized_id = '#{object.id}'"])
    cv ||= CustomValue.new
    cv.customized_type = 'WorkPackage'
    cv.customized_id = object.id
    cv.custom_field_id = WorkPackageCustomField.first(joins: :translations, conditions: ['custom_field_translations.name = ?', key]).id
    cv.value = value
    cv.save!
  end
end

# Try to assign an object the values set in a table
def send_table_to_object(object, table, except = {}, rescue_block = nil)
  return unless table.raw.present?
  as_admin do
    table.rows_hash.each do |key, value|
      _key = key.gsub(' ', '_').underscore.to_sym
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
    object.save!
  end
end

# Do something as admin
def as_admin(count = 1)
  cur_user = User.current
  User.current = User.find_by_login('admin')
  retval = nil
  count.to_i.times do
    retval = yield
  end
  User.current = cur_user
  retval
end

def plugin_loaded?(name)
  Redmine::Plugin.all.detect { |x| x.id == name.to_sym }.present?
end
