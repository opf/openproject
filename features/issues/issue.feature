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

Feature: Issue textile quickinfo links
  Background:
    Given there is 1 project with the following:
      | name        | parent      |
      | identifier  | parent      |
    And I am working in project "parent"
    And the project "parent" has the following types:
      | name | position |
      | Bug  |     1    |
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
      | edit_work_packages |
    And there is 1 user with the following:
      | login | bob|
    And the user "bob" is a "member" in the project "parent"
    And there are the following issue status:
      | name        | is_closed | is_default |
      | New         | false     | true       |
    Given the user "bob" has 1 issue with the following:
      | subject     | issue1 |
      | type        | Bug    |
    And I am already logged in as "bob"

  Scenario: Navigating from issue reports back to issue overview
    When I go to the issues/report page of the project called "parent"
    And I follow "Work packages" within "#main-menu"
    Then I should be on the issues index page of the project called "parent"

  Scenario: An issue attachment is listed
    Given the issue "issue1" has an attachment "logo.gif"
    When I go to the page for the issue "issue1"
    Then I should see "logo.gif" within ".icon-attachment"

  Scenario: Deleting an issue attachment is possible
    Given the issue "issue1" has an attachment "logo.gif"
    When I go to the page for the issue "issue1"
    Then I should see "logo.gif" within ".icon-attachment"
    When I click the first delete attachment link
    Then I should not see ".icon-attachment"
