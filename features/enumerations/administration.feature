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

Feature: Administring the enumerations

  Scenario: Creating an enumeration
    Given I am admin

    When I go to the enumerations page
    And I create a new enumeration with the following:
      | type | activity |
      | name | New enumeration   |

    Then I should be on the enumerations page
    And I should see the enumeration:
      | type | activity          |
      | name | New enumeration   |
