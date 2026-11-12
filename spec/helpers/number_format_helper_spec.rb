# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe NumberFormatHelper do
  describe "#number_with_limit" do
    [
      # Simple cases
      { input: 10, opts: {}, result: "10" },
      { input: 10.0, opts: {}, result: "10" },
      # Defaults are converting very big and very small numbers to scientific notation
      { input: 1_000_000, opts: {}, result: "1000000" },
      { input: 10_000_000, opts: {}, result: "1.0e7" },
      { input: 0.0001, opts: {}, result: "0.0001" },
      { input: 0.00001, opts: {}, result: "1.0e-5" },
      { input: 100_000.1, opts: {}, result: "100000.1" },
      { input: 100_000.0001, opts: {}, result: "1.0e5" },
      { input: 100_000.00001, opts: {}, result: "100000" },
      # precision influences scientific notation mantissa, trailing zeros are removed
      { input: 17_203_230.09932, opts: { length_limit: 8, digits: 8, precision: 3 }, result: "1.72e7" },
      { input: 17_203_230.09932, opts: { length_limit: 8, digits: 8, precision: 4 }, result: "1.7203e7" },
      { input: 17_203_230.09932, opts: { length_limit: 8, digits: 8, precision: 5 }, result: "1.72032e7" },
      # If the length limit is violated AFTER precision is rounded, use scientific notation
      { input: 17_203_230.09932, opts: { length_limit: 11, digits: 8, precision: 3 }, result: "17203230.099" },
      { input: 17_203_230.09932, opts: { length_limit: 10, digits: 8, precision: 3 }, result: "1.72e7" },
      # If digit limit before separator is violated, use scientific notation
      { input: 17_203_230.09932, opts: { length_limit: 20, digits: 8, precision: 3 }, result: "17203230.099" },
      { input: 17_203_230.09932, opts: { length_limit: 20, digits: 7, precision: 3 }, result: "1.72e7" },
      # Very small numbers (negative exponent) are rendered correctly
      { input: 7.04e-8, opts: { length_limit: 9, digits: 6, precision: 2 }, result: "7.04e-8" },
      { input: 8.402e-13, opts: { length_limit: 9, digits: 6, precision: 2 }, result: "8.4e-13" },
      # If precision is so small, the number would round to 0, show scientific notation independently of
      # not violating the length limit.
      { input: 8.402e-13, opts: { length_limit: 20, digits: 6, precision: 20 }, result: "0.0000000000008402" },
      { input: 8.402e-13, opts: { length_limit: 20, digits: 6, precision: 4 }, result: "8.402e-13" }
    ].each do |test_case|
      test_case => { input:, opts:, result: }

      it "renders #{input} with #{opts} as #{result}" do
        expect(number_with_limit(input, opts)).to eq(result)
      end
    end
  end
end
