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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Checks RFC rules in ICalConformance against an ICS string or an already parsed calendar.
#
#   expect(service.call.result).to be_a_conforming_calendar
RSpec::Matchers.define :be_a_conforming_calendar do
  match do |actual|
    @violations = ICalConformance.new(parse(actual)).violations
    @violations.empty?
  end

  failure_message do |_actual|
    violation_messages = @violations.map { "  - #{it}" }

    <<~MESSAGE
      expected ICS calendar data that conforms to RFC 5545 and RFC 5546, but found validation errors:
      #{violation_messages.join("\n")}
    MESSAGE
  end

  failure_message_when_negated do |_actual|
    "expected the calendar to break at least one ICS RFC rule, but found no validations"
  end

  def parse(actual)
    return actual if actual.is_a?(Icalendar::Calendar)

    Icalendar::Calendar.parse(actual).first
  end
end
