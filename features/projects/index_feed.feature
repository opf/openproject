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

Feature: Projects index feed
  Background:
    Given there is 1 project with the following:
      | identifier | omicronpersei8 |
      | name       | omicronpersei8 |
    And there is a role "CanViewProject"
    And the role "CanViewProject" may have the following rights:
      | view_project   |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "CanViewProject" in the project "omicronpersei8"

   Scenario: Basic columns visible
     Given I am already logged in as "bob"
     When I go to the projects page
     Then I should not see "Required disk storage" within "#project-table"
      And I should not see "Created on" within "#project-table"
      And I should not see "Latest activity at" within "#project-table"
      And I should see "Public" within "#project-table"
      And I should see "omicronpersei8" within "#project-table"

   Scenario: Admin columns visible
     Given I am already admin
     When I go to the projects page
     Then I should see "Required disk storage" within "#project-table"
      And I should see "Created on" within "#project-table"
      And I should see "Latest activity at" within "#project-table"
      And I should see "Public" within "#project-table"
      And I should see "omicronpersei8" within "#project-tablee"
