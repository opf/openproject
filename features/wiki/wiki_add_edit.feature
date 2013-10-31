Feature: Adding and Editing Wiki Tabs

Background: 

Given there is 1 project with the following:
 
     | Name | Wookies |

And the project "Wookies" uses the following modules:
		   | wiki |
And the project "Wookies" has 1 wiki page with the following:
           | Title | wookietest |

@javascript
Scenario: Adding simple wiki tab as admin
Given I am admin
And I am working in project "Wookies"
And I go to the wiki index page of the project called "Wookies"

@javascript
Scenario: Editing of wiki pages as a member with proper rights
Given there is 1 user with the following:
      | login | chewbacca|
And I am logged in as "chewbacca"
And there is a role "humanoid"
And the role "humanoid" may have the following rights:
          | view_wiki_pages |
          | edit_wiki_pages |
And the user "chewbacca" is a "humanoid" in the project "Wookies" 
When I go to the wiki page "wookietest" for the project called "Wookies"
And I click "Edit"
And I fill in "content_text" with "testing wookie"
And I click "Save"
Then I should see "testing wookie" within "#content"
