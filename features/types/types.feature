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

Feature: Types Settings
  As a Project Admin
  I want to configure which types are available in my project
  So that I can adjust the global settings inherited by the type
  So that my team and I can work effectively

  Background:
    Given there are the following types:
          | Name           | is_default |
          | Phase          | true       |
          | Milestone      | true       |
          | Something else | false      |

      And there is a project named "ecookbook"
      And I am working in project "ecookbook"

      And there is 1 user with:
          | login | padme |
      And there is a role "project admin"
      And the role "project admin" may have the following rights:
          | edit_project                 |
          | manage_types                 |
      And the user "padme" is a "project admin"

      And I am already logged in as "padme"

  Scenario: The project admin may see the currently enabled types
     When I go to the "types" tab of the settings page of the project called "ecookbook"
     Then the "Phase" checkbox should be checked
      And the "Milestone" checkbox should be checked
      And the "Something else" checkbox should not be checked

  Scenario: The project admin may set the currently enabled types
     When I go to the "types" tab of the settings page of the project called "ecookbook"
      And I check "Something else"
      And I uncheck "Milestone"
      And I press "Save"
     Then the "Phase" checkbox should be checked
      And the "Milestone" checkbox should not be checked
      And the "Something else" checkbox should be checked
