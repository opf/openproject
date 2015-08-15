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

Feature: Navigating to the work package edit page

  Background:
    Given there is 1 user with:
        | login | manager |

    And there is a role "manager"
    And the role "manager" may have the following rights:
      | edit_work_packages |
      | view_work_packages |

    And there is 1 project with the following:
      | identifier | ecookbook |
      | name       | ecookbook |
    And I am working in project "ecookbook"

    And the user "manager" is a "manager"

    And there are the following work packages in project "ecookbook":
      | subject |
      | pe1     |

    And I am already logged in as "manager"


  Scenario: Directly opening the page
    When I go to the edit page of the work package called "pe1"
    Then I should be on the edit page of the work package called "pe1"

  Scenario: From the show page of a work package
    When I go to the page of the work package called "pe1"
    And I select "Update" from the action menu
    Then I should be on the edit page of the work package called "pe1"
