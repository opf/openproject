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

Feature: Timeline View Tests
	As a Project Member
	I want to view the timeline data
	change the timeline selection

  Background:
    Given there is 1 user with:
          | login | manager |
      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines |
          | edit_timelines |
      And there is a project named "ecookbook"
      And I am working in project "ecookbook"
      And the project uses the following modules:
          | timelines |
      And the user "manager" is a "manager"
      And I am already logged in as "manager"

  Scenario: The project manager gets 'No data to display' when there are no planning elements defined
     When I go to the page of the timeline of the project called "ecookbook"
     Then I should see "New timeline report"
      And I should see "General Settings"

  Scenario: Creating a timeline
     When there is a timeline "Testline" for project "ecookbook"
     When I go to the page of the timeline "Testline" of the project called "ecookbook"
     Then I should see "New timeline report"
      And I should see "Testline"
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"

  @javascript
  Scenario: name column width
     When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table

     Then the first table column should not take more than 25% of the space
