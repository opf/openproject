#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

Given /^there are no issues$/ do
  WorkPackage.destroy_all
end

Given /^the issue "(.*?)" is watched by:$/ do |issue_subject, watchers|
  issue = WorkPackage.where(subject: issue_subject).order(:created_at).last
  watchers.raw.flatten.each do |w| issue.add_watcher User.find_by_login(w) end
  issue.save
end

Then /^the issue "(.*?)" should have (\d+) watchers$/ do |issue_subject, watcher_count|
  WorkPackage.find_by(subject: issue_subject).watchers.count.should == watcher_count.to_i
end

Given(/^the issue "(.*?)" has an attachment "(.*?)"$/) do |issue_subject, file_name|
  content_type = 'image/gif'
  issue = WorkPackage.where(subject: issue_subject).order(:created_at).last
  file = OpenProject::Files.create_temp_file name: file_name,
                                             content: 'random content which is not actually a gif'
  attachment = FactoryGirl.create :attachment,
                                  author: issue.author,
                                  content_type: content_type,
                                  file: file,
                                  container: issue,
                                  description: 'This is an attachment description'

  attachment
end

Given /^the [Uu]ser "([^\"]*)" has (\d+) [iI]ssue(?:s)? with(?: the following)?:$/ do |user, count, table|
  u = User.find_by login: user
  raise 'This user must be member of a project to have issues' unless u.projects.last
  as_admin count do
    i = FactoryGirl.create(:work_package,
                           project: u.projects.last,
                           author: u,
                           assigned_to: u,
                           status: Status.default || FactoryGirl.create(:status))

    i.type = ::Type.find_by(name: table.rows_hash.delete('type')) if table.rows_hash['type']

    send_table_to_object(i, table, {}, method(:add_custom_value_to_issue))
    i.save!
  end
end

Given /^the [Pp]roject "([^\"]*)" has (\d+) [iI]ssue(?:s)? with(?: the following)?:$/ do |project, count, table|
  p = Project.find_by(name: project) || Project.find_by(identifier: project)
  as_admin count do
    i = FactoryGirl.build(:work_package, project: p,
                                         type: p.types.first)
    send_table_to_object(i, table, {}, method(:add_custom_value_to_issue))
  end
end

When(/^I click the first delete attachment link$/) do
  within('.work-package--attachments--files') do
    find('.icon-delete', visible: false).click
  end
end

Given (/^there are the following issues(?: in project "([^"]*)")?:$/) do |project_name, table|
  table.hashes.map do |h| h['project'] = project_name end
  modified_table = Cucumber::Core::Ast::DataTable.new(table.hashes, table.location)
  argument_table = Cucumber::MultilineArgument::DataTable.new modified_table
  step %{there are the following issues with attributes:}, argument_table
end

Given (/^there are the following issues with attributes:$/) do |table|
  table = table.map_headers { |header| header.underscore.gsub(' ', '_') }
  table.hashes.each do |type_attributes|
    project  = get_project(type_attributes.delete('project'))
    attributes = type_attributes.merge(project_id: project.id) if project

    assignee = User.find_by_login(attributes.delete('assignee'))
    attributes.merge! assigned_to_id: assignee.id if assignee

    author   = User.find_by_login(attributes.delete('author'))
    attributes.merge! author_id: author.id if author

    responsible = User.find_by_login(attributes.delete('responsible'))
    attributes.merge! responsible_id: responsible.id if responsible

    watchers = attributes.delete('watched_by')

    type = ::Type.find_by(name: attributes.delete('type'))
    attributes.merge! type_id: type.id if type

    version = Version.find_by(name: attributes.delete('version'))
    attributes.merge! fixed_version_id: version.id if version

    category = Category.find_by(name: attributes.delete('category'))
    attributes.merge! category_id: category.id if category

    issue = FactoryGirl.create(:work_package, attributes)

    if watchers
      watchers.split(',').each do |w| issue.add_watcher User.find_by_login(w) end
      issue.save
    end
  end
end
