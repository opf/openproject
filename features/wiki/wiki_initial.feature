Feature: Activating and deactivating wiki menu as admin

Background:

Given I am admin 
And there is 1 project with the following:
 
     | Name | Wookie |

@javascript
Scenario:  Activation of wiki module via aproject settings as admin

When I go to the settings page of the project called "Wookie"
And I click on "tab-modules"
And I check "Wiki"
And I press "Save"
Then I should see "Wiki" within "#menu-sidebar"

@javascript
Scenario: Deactivation of wiki module via project settings

When I go to the settings page of the project called "Wookie"
And I click on "tab-modules"
And I uncheck "Wiki"
And I press "Save"
And I should not see "Wiki" within "#menu-sidebar"

