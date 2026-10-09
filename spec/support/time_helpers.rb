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

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end

RSpec::Matchers.define :equal_time_without_usec do |expected|
  expected_without_usec = expected.change(usec: 0)

  failure_message do
    actual_without_usec = actual.change(usec: 0)
    [
      "expected: #{expected_without_usec.iso8601}",
      "actual: #{actual_without_usec.iso8601}",
      "difference: #{actual_without_usec - expected_without_usec}s"
    ].join(" - ")
  end

  match do |actual|
    actual_without_usec = actual.change(usec: 0)
    expected_without_usec == actual_without_usec
  end
end

RSpec.shared_context "with default browser timezone" do
  let(:_comment) do
    "This context does not try to override the browser timezone. " \
      "It will be the same as the system (positive offset for European devs, UTC for CI, etc.)."
  end
end

RSpec.shared_context "with a negative browser timezone (New York)", driver: :chrome_new_york_time_zone do
  let(:_comment) do
    "This context overrides browser timezone to be America/New_York. " \
      "Timezone offset is -4/-5 hours (EDT/EST)."
  end
end
