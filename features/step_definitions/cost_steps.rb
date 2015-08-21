#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

Given /^the project "([^\"]+)" has (\d+) [Cc]ost(?: )?[Ee]ntr(?:ies|y)$/ do |project, count|
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  as_admin count do
    ce = FactoryGirl.build(:cost_entry)
    ce.project = p
    ce.work_package = FactoryGirl.create(:work_package, project: p)
    ce.save!
  end
end

Given /^there (?:is|are) (\d+) (default )?hourly rate[s]? with the following:$/ do |_num, is_default, table|
  if is_default
    hr = FactoryGirl.create(:default_hourly_rate)
  else
    hr = FactoryGirl.create(:hourly_rate)
  end
  send_table_to_object(hr, table,     user: Proc.new do |rate, value|
    unless rate.project.nil? || User.find_by_login(value).projects.include?(rate.project)
      Rate.update_all({ project_id:  User.find_by_login(value).projects(order: 'id ASC').last.id },
                      id: rate.id)
    end
    Rate.update_all({ user_id: User.find_by_login(value).id },
                    id: rate.id)
  end,
                                      valid_from: Proc.new do |rate, value|
                                        # This works for definitions like "2 years ago"
                                        number, time_unit, tempus = value.split
                                        time = number.to_i.send(time_unit.to_sym).send(tempus.to_sym)
                                        rate.update_attribute :valid_from, time
                                      end)
end

Given /^the [Uu]ser "([^\"]*)" has (\d+) [Cc]ost(?: )?[Ee]ntr(?:ies|y)$/ do |user, count|
  u = User.find_by_login user
  p = u.projects.last
  i = FactoryGirl.create(:work_package, project: p)
  as_admin count do
    ce = FactoryGirl.create(:cost_entry)
    ce.user = u
    ce.project = p
    ce.work_package = i
    ce.save!
  end
end

Given /^the project "([^\"]+)" has (\d+) [Cc]ost(?: )?[Ee]ntr(?:ies|y) with the following:$/ do |project, count, table|
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  i = FactoryGirl.create(:work_package, project: p)
  as_admin count do
    ce = FactorGirl.build(:cost_entry)
    ce.project = p
    ce.work_package = i
    send_table_to_object(ce, table)
    ce.save!
  end
end

Given /^the work package "([^\"]+)" has (\d+) [Cc]ost(?: )?[Ee]ntr(?:ies|y) with the following:$/ do |work_package, count, table|
  i = WorkPackage.where(subject: work_package.subject).last
  as_admin count do
    ce = FactoryGirl.build(:cost_entry, spent_on: (table.rows_hash['date'] ? table.rows_hash['date'].to_date : Date.today),
                                        units: table.rows_hash['units'],
                                        project: i.project,
                                        work_package: i,
                                        user: User.find_by_login(table.rows_hash['user']),
                                        comments: 'lorem')

    ce.cost_type = CostType.find_by_name(table.rows_hash['cost type']) if table.rows_hash['cost type']

    ce.save!
  end
end

Given /^there is a standard cost control project named "([^\"]*)"$/ do |name|
  steps %{
    Given there is 1 project with the following:
      | Name | #{name} |
      | Identifier | #{name.gsub(' ', '_').downcase} |
    And the project "#{name}" has the following types:
      | name     |
      | type1 |
    And the project "#{name}" has 1 subproject
    And the project "#{name}" has 1 issue with:
      | subject | #{name}work_package |
    And there is a role "Manager"
    And the role "Manager" may have the following rights:
      | view_own_hourly_rate |
      | view_work_packages |
      | view_work_packages |
      | view_own_time_entries |
      | view_own_cost_entries |
      | view_cost_rates |
    And there is a role "Controller"
    And the role "Controller" may have the following rights:
      | View own cost entries |
    And there is a role "Developer"
    And the role "Developer" may have the following rights:
      | View own cost entries |
    And there is a role "Reporter"
    And the role "Reporter" may have the following rights:
      | Create work packages |
    And there is a role "Supplier"
    And the role "Supplier" may have the following rights:
      | View own hourly rate |
      | View own cost entries |
    And there is 1 user with:
      | Login | manager |
    And the user "manager" is a "Manager" in the project "#{name}"
    And there is 1 user with:
      | Login | controller |
    And the user "controller" is a "Controller" in the project "#{name}"
    And there is 1 user with:
      | Login | developer |
    And the user "developer" is a "Developer" in the project "#{name}"
    And there is 1 user with:
      | Login | reporter |
    And the user "reporter" is a "Reporter" in the project "#{name}"
  }
end

Given /^users have times and the cost type "([^\"]*)" logged on the work package "([^\"]*)" with:$/ do |cost_type, work_package, table|
  i = WorkPackage.where(subject: work_package.subject).last
  raise "No such work_package: #{work_package}" unless i

  table.rows_hash.map do |k, v|
    user = k.split.first
    if k.end_with? 'hours'
      steps %{
        And the issue "#{work_package}" has 1 time entry with the following:
          | hours     | #{v}    |
          | user      | #{user} |
      }
    elsif k.end_with? 'units'
      steps %{
        And the issue "#{work_package}" has 1 cost entry with the following:
        | units     | #{v}         |
        | user      | #{user}      |
        | cost type | #{cost_type} |
      }
    elsif k.end_with? 'rate'
      steps %{
        And the user "#{user}" has:
          | default rate | #{v} |
      }
    else
      "Don't know what to do with #{k} => #{v}. Use | <username> (hours|rate|units) | <x> | as."
      next
    end
  end
end

Given /^there is a (?:variable cost object|budget) with the following:$/ do |table|
  cost_object = FactoryGirl.build(:variable_cost_object)

  table_hash = table.rows_hash

  cost_object.created_on = table_hash.has_key?('created_on') ?
                             eval(table_hash['created_on']) :
                             Time.now
  cost_object.fixed_date = cost_object.created_on.to_date
  cost_object.project = (Project.find_by_identifier(table_hash['project']) || Project.find_by_name(table_hash ['project'])) if table_hash.has_key? 'project'
  cost_object.author = User.find_by_login(table_hash['author']) || cost_object.project.members.first.principal
  cost_object.subject = table_hash['subject'] if table_hash.has_key? 'subject'

  cost_object.save!
  cost_object.journals.first.update_attribute(:created_at, eval(table_hash['created_on'])) if table_hash.has_key?('created_on')
end

Given /^I update the variable cost object "([^"]*)" with the following:$/ do |subject, table|
  cost_object = VariableCostObject.find_by_subject(subject)

  cost_object.subject = table.rows_hash['subject']
  cost_object.save!
end

Given /^the (?:variable cost object|budget) "(.+)" has the following labor items:$/ do |subject, table|
  cost_object = VariableCostObject.find_by_subject(subject)

  table.hashes.each do |hash|
    user = User.find_by_login(hash['user']) || User.find_by_name(hash['user']) || cost_object.project.members.first.principal
    FactoryGirl.create(:labor_budget_item, user: user, cost_object: cost_object, comments: hash['comment'], hours: hash['hours'])
  end
end

Given /^the (?:variable cost object|budget) "(.+)" has the following material items:$/ do |subject, table|
  cost_object = VariableCostObject.find_by_subject(subject)

  table.hashes.each do |hash|
    cost_type = CostType.find_by_name(hash['cost_type']) || Cost_type.first
    FactoryGirl.create(:material_budget_item, cost_type: cost_type, cost_object: cost_object, comments: hash['comment'], units: hash['units'])
  end
end
