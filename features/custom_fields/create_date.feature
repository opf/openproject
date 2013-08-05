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

Feature: Date custom fields can be created

  Background:
    Given I am already admin
    And the following languages are active:
      | en |
      | de |
    When I go to the custom fields page
    When I follow "New custom field" within "#tab-content-WorkPackageCustomField"

  @javascript
  Scenario: Creating a date custom field
    When I select "Date" from "custom_field_field_format"
    And I set the english localization of the "name" attribute to "New Field"
    And I set the english localization of the "default_value" attribute to "2012-01-01"
    And I press "Save"
    Then I should be on the custom fields page
