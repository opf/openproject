#-- copyright
#
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
#
Feature: Logging time on work package update
  Background:
    Given there is 1 user with:
      | login     | manager |
      | firstname | the     |
      | lastname  | manager |
    And there is 1 project with the following:
      | identifier | ecookbook |
      | name       | ecookbook |
    And there is a role "manager"
    And the role "manager" may have the following rights:
      | edit_work_packages |
      | view_work_packages |
      | log_time           |
    And I am working in project "ecookbook"
    And the user "manager" is a "manager"
    And there are the following status:
      | name    | default |
      | status1 | true    |
    And there are the following work packages in project "ecookbook":
      | subject |
      | pe1     |
    And there is an activity "design"
    And I am already logged in as "manager"

  Scenario: Logging time
    When I go to the edit page of the work package called "pe1"
     And I fill in the following:
       | Spent time | 5         |
       | Activity   | design    |
       | Comment    | Needed it |
     And I submit the form by the "Submit" button

    Then the work package should be shown with the following values:
       | Spent time | 5.00      |
