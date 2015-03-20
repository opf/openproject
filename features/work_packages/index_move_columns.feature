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

Feature: Disabled done ratio on the work package index

  Background:
    Given there is 1 project with the following:
      | identifier | project1 |
      | name       | project1 |

    And I am working in project "project1"

    And the project "project1" has the following types:
      | name    | position |
      | Bug     |     1    |
      | Feature |     2    |

    And there is a role "member"

    And the role "member" may have the following rights:
      | view_work_packages |

    And there is 1 user with the following:
      | login | bob |
    And there is 1 user with the following:
      | login | jimmy |

    And the user "bob" is a "member" in the project "project1"
    And the user "jimmy" is a "member" in the project "project1"

    And there are the following issues in project "project1":
      | subject | type    | author | assignee |
      | issue1  | Bug     | bob    | jimmy    |
      | issue2  | Feature | bob    | jimmy    |
      | issue3  | Bug     | bob    | jimmy    |
      | issue4  | Feature | jimmy  | bob      |
      | issue5  | Bug     | jimmy  | bob      |
      | issue6  | Feature | jimmy  | bob      |

    And I am already logged in as "bob"

  @javascript
  Scenario: Author column should be displayed when Author is moved to selected columns
    When I go to the work packages index page of the project "project1"
    And I choose "Columns" from the toolbar "settings" dropdown
    And I select to see column "Author"
    And I click "Apply"
    Then I should see "Author" within ".workpackages-table"

  @javascript
  Scenario: Subject column should not be displayed when Subject is moved out of selected columns
    When I go to the work packages index page of the project "project1"
    And I choose "Columns" from the toolbar "settings" dropdown
    And I select to not see column "Subject"
    Then I should not see "Subject" within ".workpackages-table"
