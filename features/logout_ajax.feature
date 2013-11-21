#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

Feature: Doing Ajax when logged out
  Background:
      And there is 1 user with:
          | login | manager |

      And there are the following project types:
          | Name                  |
          | Standard Project      |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_work_packages    |

      And there is a project named "ecookbook" of type "Standard Project"
      And I am working in project "ecookbook"

      And the user "manager" is a "manager"

      And I am logged in as "manager"

  @javascript
  Scenario: If we do ajax while being logged out a confirm dialog should open
    When I go to the work packages index page of the project "ecookbook"
      And I log out in the background
      And I do some ajax
      And I confirm popups
    Then I should be on the login page
