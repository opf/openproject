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

Feature: Project creation with support for project type
  As a ChiliProject Admin
  I want to set a project type when creating a project
  So that the default planning element types are enabled automatically

  Background:
    Given there are the following types:
          | Name           | Is default |
          | Phase          | true       |
          | Milestone      | false      |
          | Something else | false      |

      And there are the following project types:
          | Name                  |
          | Standard Project      |
          | Extraordinary Project |

  Scenario: The admin may create a project with a project type
    Given I am already admin
     When I go to the admin page
      And I follow the first link matching "Projects"
      And I follow "New project"
     Then I fill in "Fancy Pants" for "Name"
      And I fill in "fancy-pants" for "Identifier"
      And I check "Timelines"
      And I select "Standard Project" from "Project type"
      And I press "Save"

     Then I should see a notice flash stating "Successful creation."

     When the following types are enabled for projects of type "Standard Project"
          | Phase     |
          | Milestone |
      And I go to the "types" tab of the settings page of the project called "Fancy Pants"

     Then the "Phase" checkbox should be checked
      And the "Milestone" checkbox should be checked
