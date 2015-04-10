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

Feature: Calculated sums on the work package index

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
      | subject | type    | author | assignee | estimated_hours |
      | issue1  | Bug     | bob    | jimmy    | 10              |
      | issue2  | Feature | bob    | jimmy    | 8               |
      | issue3  | Bug     | bob    | jimmy    | 0               |
      | issue4  | Feature | jimmy  | bob      | 0               |
      | issue5  | Bug     | jimmy  | bob      | 5               |
      | issue6  | Feature | jimmy  | bob      | 3               |

    And I am already logged in as "bob"

  @javascript
  Scenario: Total sum of summable column should be displayed when display sums checkbox is checked
    When I go to the work packages index page of the project "project1"
    # Adding this "should see" to prevent the columns menu from being opened
    # before the information on available columns is returned from the server.
    # If it is opened before the modal is empty.
    And I should see "subject" within ".workpackages-table"
    And I choose "Columns" from the toolbar "settings" dropdown
    And I select to see column "Estimated time"
    And I click "Apply"
    And I choose "Display sums" from the toolbar "settings" dropdown
    Then I should see "26" within ".sum.group.all"
