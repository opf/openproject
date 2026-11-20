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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module Import
    module CSV
      # Reads the date and the date and time cells of an imported file.
      #
      # The date is written year first, the one order that cannot be read two ways: 03/04 is two
      # different days on either side of the Atlantic, and a file is no place to guess. The rest is
      # where the spreadsheets people import from differ, so the separator between the date and the
      # time, the seconds, the fraction, the meridian and the time zone are all optional, and a cell
      # without a zone is read in the time zone of the user running the import.
      module DateParser
        DATE = %r{\A(?<year>\d{4})(?<separator>[-/])(?<month>\d{1,2})\k<separator>(?<day>\d{1,2})}
        TIME = /\A(?<hour>\d{1,2}):(?<minute>\d{2})(?::(?<second>\d{2})(?:\.\d+)?)?
               (?<meridian>\s*[ap]\.?m\.?)?
               (?<zone>\s*(?:z|[+-]\d{1,2}:?(?:\d{2})?|[a-z]{2,5}(?:[+-]\d{1,2}(?::?\d{2})?)?))?
               \z/xi
        SEPARATOR = /\A[t ]/i

        Reading = Data.define(:date, :time)
        private_constant :Reading

        module_function

        # @return [Date, nil] the date the cell names, whatever time it carries, or nil where the
        #   cell is not one this reads
        def date(raw) = read(raw)&.date

        # @return [ActiveSupport::TimeWithZone, nil] nil where the cell is not one this reads
        def timestamp(raw)
          reading = read(raw)
          return nil if reading.nil?

          Time.zone.parse("#{reading.date.iso8601} #{reading.time}")
        rescue ArgumentError
          nil
        end

        def read(raw)
          value = raw.to_s.strip
          match = DATE.match(value)
          return nil if match.nil?

          date = calendar_date(match)
          time = value[match.end(0)..].sub(SEPARATOR, "").strip
          return nil if date.nil? || !readable_time?(value, time)

          Reading.new(date:, time:)
        end

        def calendar_date(match)
          year, month, day = match.values_at(:year, :month, :day).map(&:to_i)

          Date.new(year, month, day) if Date.valid_date?(year, month, day)
        end

        # A zone Ruby cannot place would otherwise be dropped in silence, leaving the cell read in
        # the importing user's own zone rather than the one it names.
        def readable_time?(value, time)
          return true if time.empty?

          match = TIME.match(time)
          return false if match.nil? || !clock?(match)

          match[:zone].nil? || ::Date._parse(value)[:offset].present?
        end

        # Ruby carries a 24th hour over into the next day, which turns a mistyped cell into a
        # moment nobody wrote.
        def clock?(match)
          hour = match[:hour].to_i
          hours = match[:meridian] ? (1..12) : (0..23)

          hours.cover?(hour) && match[:minute].to_i <= 59 && match[:second].to_i <= 59
        end

        private_class_method :read, :calendar_date, :readable_time?, :clock?
      end
    end
  end
end
