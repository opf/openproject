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

Feature: Prevent brute force attacks
  Background:
    Given users are blocked for 5 minutes after 2 failed login attempts
    And there is a user named "bob"

  Scenario: A user failing to login on the first time can login on second attempt
    When I try to log in with user "bob" and a wrong password
    Then I should not see "Bob Bobbit"
    When I try to log in with user "bob"
    Then I should see "Bob Bobbit"

  Scenario: A user can't login after two failed attempts, but can after waiting 5 minutes
    When I try to log in with user "bob" and a wrong password
    Then I should not see "Bob Bobbit"
    When I try to log in with user "bob" and a wrong password
    Then I should not see "Bob Bobbit"
    When I try to log in with user "bob"
    Then I should not see "Bob Bobbit"
    When the time is 6 minutes later
    And I try to log in with user "bob"
    Then I should see "Bob Bobbit"

  Scenario: Brute force prevention is disabled
    Given users are blocked for 5 minutes after 0 failed login attempts
    When I try to log in with user "bob" and a wrong password
    Then I should not see "Bob Bobbit"
    When I try to log in with user "bob"
    Then I should see "Bob Bobbit"
