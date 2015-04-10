#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Project Association Management
  As a Project Member
  I want to view, edit and delete project associations for my project
  So that I can document dependencies to other projects properly

  Background:
    Given there are the following project types:
          | Name              | Allows Association |
          | Waterfall Project | true               |
          | Scrum Project     | true               |

      And there are the following roles:
          | Viewer        |
          | Editor        |
          | Project Admin |

      And the role "Viewer" may have the following rights:
          | view_timelines              |
          | view_project_associations   |

      And the role "Editor" may have the following rights:
          | view_timelines              |
          | view_project_associations   |
          | edit_project_associations   |

      And the role "Project Admin" may have the following rights:
          | view_timelines              |
          | view_project_associations   |
          | edit_project_associations   |
          | delete_project_associations |

      And there are the following projects of type "Waterfall Project":
          | My Project |
          | Visible    |
          | Public     |
          | Other      |

      And there is a project named "Scrum" of type "Scrum Project"

      And the project "My Project" is not public
      And the project "Other" is not public
      And the project "Scrum" is not public
      And the project "Visible" is not public
      And the project "Public" is public


      And there are the following users:
          | Viewer        |
          | Editor        |
          | Project-Admin |

      And the user "Viewer" is a "Viewer" in the project "Scrum"
      And the user "Editor" is a "Viewer" in the project "Scrum"
      And the user "Project-Admin" is a "Viewer" in the project "Scrum"

      And the user "Viewer" is a "Viewer" in the project "Visible"
      And the user "Editor" is a "Viewer" in the project "Visible"
      And the user "Project-Admin" is a "Viewer" in the project "Visible"

      And I am working in project "My Project"

      And the project uses the following modules:
          | timelines |

      And the user "Viewer" is a "Viewer"
      And the user "Editor" is a "Editor"
      And the user "Project-Admin" is a "Project Admin"

  Scenario: Reader does not render anything when there are no project associations
    Given I am already logged in as "Viewer"
     When I go to the   page of the project called "My Project"
      And I toggle the "Timelines" submenu
      And I follow "Dependencies"

     Then I should not see "Waterfall Project"
      And I should not see "Scrum Project"
      And I should not see "No data to display"

  Scenario: Reader gets 'No data to display' when there are associations to unknown projects
    Given I am already logged in as "Viewer"
      And there are the following project associations:
          | Project A  | Project B |
          | My Project | Other     |

     When I go to the   page of the project called "My Project"
      And I toggle the "Timelines" submenu
      And I follow "Dependencies"

     Then I should not see "Waterfall Project"
      And I should not see "Scrum Project"
      And I should not see "No data to display"

  Scenario: Reader sees associations to projects where s/he is member and to public ones
    Given I am already logged in as "Viewer"
      And there are the following project associations:
          | Project A  | Project B  |
          | My Project | Visible    |
          | My Project | Public     |
          | Scrum      | My Project |

     When I go to the   page of the project called "My Project"
      And I toggle the "Timelines" submenu
      And I follow "Dependencies"

     Then I should see "Visible" below "Waterfall Project"
      And I should see "Public" below "Waterfall Project"
      And I should see "Scrum" below "Scrum Project"

  Scenario: Reader is not able to add associations
    Given I am already logged in as "Viewer"
     When I go to the   page of the project called "My Project"
      And I click on "Dependencies"
      And I should not be able to add new project associations

  @javascript
  Scenario: Editor is able to add associations
    Given I am already logged in as "Editor"
     When I go to the   page of the project called "My Project"
      And I toggle the "Timelines" submenu
      And I click on "Dependencies"
      And I click on "New dependency"

     When I select "Visible" from "Set dependency for “My Project” with"
      And I fill in "A good reason" for "Cause"
      And I press "Add dependency"

     Then I should see a notice flash stating "Successful creation."
      And I should see "Visible" below "Waterfall Project"

  Scenario: Editor is able to edit associations
    Given I am already logged in as "Editor"
      And there are the following project associations:
          | Project A  | Project B | Description   |
          | My Project | Visible   | A good reason |
     When I go to the   page of the project called "My Project"
      And I toggle the "Timelines" submenu
      And I follow "Dependencies"

     When I follow "Edit Visible"
      And I fill in "A better reason" for "Cause"
      And I press "Update"

     Then I should see a notice flash stating "Successful update."
      And I should see "A better reason" below "Waterfall Project"

   Scenario: Editor cannot delete associations
    Given I am already logged in as "Editor"
      And there are the following project associations:
          | Project A  | Project B | Description   |
          | My Project | Visible   | A good reason |
     When I go to the   page of the project called "My Project"
      And I toggle the "Timelines" submenu
      And I follow "Dependencies"

     Then I should not see "Delete Visible"

   Scenario: Project-Admin may delete associations
    Given I am already logged in as "Project-Admin"
      And there are the following project associations:
          | Project A  | Project B | Description   |
          | My Project | Visible   | A good reason |
     When I go to the   page of the project called "My Project"
      And I toggle the "Timelines" submenu
      And I follow "Dependencies"

     When I follow "Delete Visible"
      And I press "Delete"

     Then I should see a notice flash stating "Successful deletion."
     Then I should not see "Waterfall Project"
      And I should not see "Scrum Project"
      And I should not see "No data to display"
      And I should not see "A good reason"
