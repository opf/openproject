# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
# ++

# When you need to check an attribute for multiple records:
#
#   expect(WorkPackage.where(sprint:)).to pluck(:position).eq(
#     sprint1_wp2 => 1,
#     sprint1_wp3 => 2,
#     sprint1_wp4 => 3,
#     sprint1_wp1 => 4,
#     sprint1_wp5 => 6
#   )
#
# Fails with:
#
#    582 => 1,
#    583 => 2,
#    584 => 3,
#   -585 => 6,
#   +585 => 5,
#
# Specify `identified_by` attribute to be used instead of `id` to differentiate
# records in failurediff, it must be unique:
#
#   expect(WorkPackage.where(sprint:)).to pluck(:position, identified_by: :subject).eq(
#     sprint1_wp2 => 1,
#     sprint1_wp3 => 2,
#     sprint1_wp4 => 3,
#     sprint1_wp1 => 4,
#     sprint1_wp5 => 6
#   )
#
# Fails with:
#
#    "Sprint 1 WorkPackage 2" => 1,
#    "Sprint 1 WorkPackage 3" => 2,
#    "Sprint 1 WorkPackage 4" => 3,
#   -"Sprint 1 WorkPackage 5" => 6,
#   +"Sprint 1 WorkPackage 5" => 5,

RSpec::Matchers.define :pluck do |attribute, identified_by: :id|
  chain :eq do |expected|
    @expected = expected.transform_keys { it.public_send(identified_by) }
  end

  match do |actual|
    @actual = actual.pluck(identified_by, attribute).to_h
    @actual == @expected
  end

  diffable

  define_method(:expected) { @expected }

  failure_message do |_|
    "expected #{attribute.inspect} (identified by #{identified_by.inspect}) to match"
  end
end
