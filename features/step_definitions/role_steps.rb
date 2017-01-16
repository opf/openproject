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

Given /^the [Uu]ser "([^\"]*)" is a "([^\"]*)" (?:in|of) the [Pp]roject "([^\"]*)"$/ do |user, role, project|
  u = User.find_by_login(user)
  r = Role.find_by(name: role)
  p = Project.find_by(name: project) || Project.find_by(identifier: project)
  as_admin do
    Member.new.tap do |m|
      m.user = u
      m.roles << r
      m.project = p
    end.save!
  end
end

Given /^there is a [rR]ole "([^\"]*)"$/ do |name, _table = nil|
  FactoryGirl.create(:role, name: name) unless Role.find_by(name: name)
end

Given /^there is a [rR]ole "([^\"]*)" with the following permissions:?$/ do |name, table|
  FactoryGirl.create(:role, name: name, permissions: table.raw.flatten) unless Role.find_by(name: name)
end

Given /^there are the following roles:$/ do |table|
  table.raw.flatten.each do |name|
    FactoryGirl.create(:role, name: name) unless Role.find_by(name: name)
  end
end

Given /^the [rR]ole "([^\"]*)" may have the following [rR]ights:$/ do |role, table|
  r = Role.find_by(name: role)
  raise "No such role was defined: #{role}" unless r
  as_admin do
    available_perms = Redmine::AccessControl.permissions.map(&:name)
    r.permissions = []

    table.raw.each do |_perm|
      perm = _perm.first
      unless perm.blank?
        perm = perm.gsub(' ', '_').underscore.to_sym
        if available_perms.include?(:"#{perm}")
          r.add_permission! perm
        end
      end
    end

    r.save!
  end
end

Given /^the [rR]ole "(.+?)" has no (?:[Pp]ermissions|[Rr]ights)$/ do |role_name|
  role = Role.find_by(name: role_name)
  raise "No such role was defined: #{role_name}" unless role
  as_admin do
    role.permissions = []
    role.save!
  end
end

Given /^the user "(.*?)" is a "([^\"]*?)"$/ do |user, role|
  step %{the user "#{user}" is a "#{role}" in the project "#{get_project.name}"}
end
