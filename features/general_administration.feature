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

Feature: General Timelines administration
  As a ChiliProject Admin
  I want to see useful information instead of an empty table
  So that I can see the reason why I cannot see anything

  Scenario: The admin gets 'There are currently no colors' when there are no colors defined
    Given I am already admin
     When I go to the admin page
      And I follow "Colors"
     Then I should see "There are currently no colors"
      And I should see "New color"

  Scenario: The admin gets 'There are currently no project types' when there are no project types defined
    Given I am already admin
     When I go to the admin page
      And I follow "Project types"
     Then I should see "There are currently no project types"
      And I should see "New project type"
