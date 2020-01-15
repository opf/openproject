#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

InstanceFinder.register(IssuePriority, Proc.new { |name| IssuePriority.find_by(name: name) })

Given /^there is a(?:n)? (default )?issuepriority with:$/ do |default, table|
  name = table.raw.find { |ary| ary.include? 'name' }[table.raw.first.index('name') + 1].to_s
  project = get_project
  FactoryBot.build(:priority).tap do |prio|
    prio.name = name
    prio.is_default = !!default
    prio.project = project
  end.save!
end

Given /^there are the following priorities:$/ do |table|
  table.hashes.each do |row|
    project = get_project

    FactoryBot.build(:priority).tap do |prio|
      prio.name = row[:name]
      prio.is_default = row[:default] == 'true'
      prio.project = project
    end.save!
  end
end
