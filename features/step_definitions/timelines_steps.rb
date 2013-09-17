#encoding: utf-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

# Merge those two once Issue == PlanningElement == WorkPackage
Then(/^I should (not )?see the planning element "(.*?)" in the timeline$/) do |negate, planning_element_name|
  steps %Q{
    Then I should #{negate}see "#{planning_element_name}" within ".timeline .tl-left-main"
  }
end

Then(/^I should (not )?see the issue "(.*?)" in the timeline$/) do |negate, issue_name|
  steps %Q{
    Then I should #{negate}see "#{issue_name}" within ".timeline .tl-left-main"
  }
end
