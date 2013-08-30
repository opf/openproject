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

Feature: Renaming a wiki page

  Background:
    Given there is 1 user with the following:
      | login | bob |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_wiki_pages   |
      | edit_wiki_pages   |
      | rename_wiki_pages |
    And there is 1 project with the following:
      | name       | project1 |
      | identifier | project1 |
    And the user "bob" is a "member" in the project "project1"
    And the project "project1" has 1 wiki page with the following:
      | title | WikiPage |
    And I am already logged in as "bob"

  @javascript
  Scenario: Renaming a wiki page
    When I go to the wiki page "WikiPage" of the project called "project1"
    And I click on "More functions"
    And I click on "Rename"
    And I fill in "New WikiPage" for "Title"
    And I press "Rename"
    Then I should be on the wiki page "New_WikiPage" of the project called "project1"
    And I should see "Successful update." within ".notice"
