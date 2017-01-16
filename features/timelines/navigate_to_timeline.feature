#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

Feature: Navigating to the timeline page

  Background:
      And there is 1 user with:
          | login | manager |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines                  |

      And there is a project named "ecookbook"
      And I am working in project "ecookbook"

      And the project uses the following modules:
          | timelines |

      And the user "manager" is a "manager"

      And I am already logged in as "manager"

  Scenario: Navigating to the timeline page via the menu
     When I go to the home page of the project called "ecookbook"
      And I follow "Timelines"
     Then I should be on the new timeline page of the project called "ecookbook"

  Scenario: When navigating via the menu the first timeline is presented by default
     When there is a timeline "Testline" for project "ecookbook"
     When there is a timeline "Testline2" for project "ecookbook"
      And I go to the page of the project called "ecookbook"
      And I follow "Timelines"
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"
