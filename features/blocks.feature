#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Behavior of specific blocks (news, issues - this is currently not complete!!)
  Background:
    Given there is 1 project with the following:
      | name        | tested_project      |
    And the project "tested_project" has the following types:
      | name | position |
      | Bug  |     1    |
    And there is 1 project with the following:
      | name        | other_project      |
    And the project "other_project" has the following types:
      | name | position |
      | Bug  |     1    |
    And there is 1 user with the following:
      | login      | bob      |
    And there is 1 user with the following:
      | login      | mary      |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
      | create_work_packages |
    And the user "bob" is a "member" in the project "tested_project"
    And the user "bob" is a "member" in the project "other_project"
    And I am logged in as "bob"



  Scenario: In the news Section, I should only see news for the selected project
    And project "tested_project" uses the following modules:
      | news |
    And the following widgets are selected for the overview page of the "tested_project" project:
      #TODO mapping from the human-name back to it's widget-name??!
      | top        | news_latest   |
    Given there is a news "test-headline" for project "tested_project"
    And there is a news "NO-SHOW" for project "other_project"
    And I am on the homepage for the project "tested_project"
    Then I should see the widget "news_latest"
    And I should see the news-headline "test-headline"
    And I should not see the news-headline "NO-SHOW"

  Scenario: In the 'Work packages reported by me'-Section, I should only see work packages for the selected project
    And there are the following issues with attributes:
      | subject     | project        | author  |
      | Test-Issue  | tested_project | bob     |
      | NO-SHOW     | other_project  | bob     |
    And the following widgets are selected for the overview page of the "tested_project" project:
      | top        | work_packages_reported_by_me |
    And I am on the homepage for the project "tested_project"
    Then I should see the widget "work_packages_reported_by_me"
    And I should see the work-package-subject "Test-Issue" in the 'Work packages reported by me'-section
    And I should not see the work-package-subject "NO-SHOW" in the 'Work packages reported by me'-section

  Scenario: In the 'Work packages assigned to me'-Section, I should only see work packages for the selected project
    And there are the following issues with attributes:
      | subject     | project        | author  | assignee  |
      | Test-Issue  | tested_project | bob     | bob       |
      | NO-SHOW     | tested_project | bob     | mary      |
    And the following widgets are selected for the overview page of the "tested_project" project:
      | top        | work_packages_assigned_to_me |
    And I am on the homepage for the project "tested_project"
    Then I should see the widget "work_packages_assigned_to_me"
    And I should see the work-package-subject "Test-Issue" in the 'Work packages assigned to me'-section
    And I should not see the work-package-subject "NO-SHOW" in the 'Work packages assigned to me'-section

  Scenario: In the 'Work packages watched by me'-Section, I should only see work packages for the selected project
    And there are the following issues with attributes:
      | subject     | project        | author  | watched_by |
      | Test-Issue  | tested_project | bob     | bob        |
      | NOT-WATCHED | other_project  | bob     | bob,mary   |
    And the following widgets are selected for the overview page of the "tested_project" project:
      | top        | work_packages_watched |
    And I am on the homepage for the project "tested_project"
    Then I should see the widget "work_packages_watched"
    And I should see the work-package-subject "Test-Issue" in the 'Work packages watched'-section
    And I should not see the work-package-subject "NOT-WATCHED" in the 'Work packages watched'-section
