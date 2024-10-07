#-- copyright
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
#++

# Differ is private, so this can break at any moment
# Example:
#     expect([1, 2, 3]).to eq_array [2, 3, 4]
#     expect(actual).to eq_array(expected) { [_1.id, _1.value] }
RSpec::Matchers.define :eq_array do |expected|
  match { |actual| expected == actual }

  failure_message do |actual|
    actual_values = block_arg ? actual.map(&block_arg) : actual
    expected_values = block_arg ? expected.map(&block_arg) : expected

    diff = RSpec::Expectations.differ.diff(
      actual_values.map(&:inspect).join("\n"),
      expected_values.map(&:inspect).join("\n")
    )

    <<~MESSAGE
      expected: #{expected_values}
           got: #{actual_values}

      #{diff}
    MESSAGE
  end
end
