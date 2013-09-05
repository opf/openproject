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

Feature: Error messages are displayed

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
    And there are the following work packages in project "ecookbook":
      | subject |
      | pe1     |
    And there is an activity "design"
    And I am already logged in as "manager"

  @javascript
  Scenario: Inserting a blank subject results in an error beeing shown
    When I go to the edit page of the work package called "pe1"
     And I follow "More"
     And I fill in the following:
       | Subject | |
     And I submit the form by the "Submit" button

    Then I should see an error explanation stating "Subject can't be blank"
