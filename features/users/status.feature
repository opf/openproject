#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

Feature: User Status
  Background:
    Given I am already admin
    Given there is a user named "bobby"

  Scenario: A locked and blocked user gets unlocked and unblocked
    Given the user "bobby" is locked
    And the user "bobby" had too many recently failed logins
    When I edit the user "bobby"
    And I click "Unlock and reset failed logins"
    When I try to log in with user "bobby"
    Then I should see "Bob Bobbit" as being logged in

  Scenario: A registered user gets activated
    Given the user "bobby" is registered and not activated
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit"
    When I am already admin
    And I edit the user "bobby"
    And I click "Activate"
    When I try to log in with user "bobby"
    Then I should see "Bob Bobbit" as being logged in
