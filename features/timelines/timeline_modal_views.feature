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

Feature: Timeline View Tests
	As a Project Member
	I want edit planning elements via a modal window

  Background:
     Given there is 1 user with:
          | login | manager |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines     |
          | edit_timelines     |
          | view_work_packages |

      And there is a project named "ecookbook"
      And I am working in project "ecookbook"

      And there is a timeline "Testline" for project "ecookbook"

      And the project uses the following modules:
          | timelines |

      And the user "manager" is a "manager"

      And there are the following work packages:
          | Start date | Due date   | description         | responsible | Subject  |
          | 2012-01-01 | 2012-01-31 | #2 http://google.de | manager     | January  |
          | 2012-02-01 | 2012-02-24 | Avocado Rincon      | manager     | February |

      And I am already logged in as "manager"

  @javascript
  Scenario: planning element click should show modal window
     When I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
      And I click on the Planning Element with name "January"
     Then I should see a modal window
      And I should see "#1: January" in the modal
      And I should see "http://google.de" in the modal
      And I should see "01/01/2012" in the modal
      And I should see "01/31/2012" in the modal
      And I should see "New timeline report"
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"
     When I ctrl-click on "#2" in the modal
     Then I should see "February" in the new window
     Then I should see "Avocado Rincon" in the new window

  @javascript
  Scenario: closing the modal window with changes should display a warning message
    When the role "manager" may have the following rights:
      | view_timelines     |
      | edit_timelines     |
      | view_work_packages |
      | edit_work_packages |
    And I go to the page of the timeline "Testline" of the project called "ecookbook"
    And I wait for timeline to load table
    And I click on the Planning Element with name "January"
    And I click on the first anchor matching "Update" in the modal
    And I fill in "work_package_journal_notes" with "A new comment" in the modal
    And I click on the div "ui-dialog-closer"
    And I confirm the JS confirm dialog
   Then I should not see a modal window
  # Hack to ensure that this scenario does not interfere with the next one.  As
  # closing the modal will trigger the timeline to be reloaded we have to
  # ensure, that this request is finished before starting the next scenario.
  # Otherwise the data required to successfully finish the request (esp. the
  # project) might already be removed for the next senario.
  Given I wait for the AJAX requests to finish

  @javascript
  Scenario: closing the modal window after adding a related work package should not display a warning message
    When the role "manager" may have the following rights:
      | view_timelines     |
      | edit_timelines     |
      | view_work_packages |
      | edit_work_packages |
      | manage_work_package_relations |
    And I go to the page of the timeline "Testline" of the project called "ecookbook"
    And I wait for timeline to load table
    And I click on the Planning Element with name "January"
    And I click on "Add related work package" in the modal
    And I fill in "relation_to_id" with "3" in the modal
    And I press "Add" in the modal
    And I wait for the AJAX requests to finish
    And I click on the div "ui-dialog-closer"
   Then I should not see a modal window
  # Hack to ensure that this scenario does not interfere with the next one.  As
  # closing the modal will trigger the timeline to be reloaded we have to
  # ensure, that this request is finished before starting the next scenario.
  # Otherwise the data required to successfully finish the request (esp. the
  # project) might already be removed for the next senario.
  Given I wait for the AJAX requests to finish
