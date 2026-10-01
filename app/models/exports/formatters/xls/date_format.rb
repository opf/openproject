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

module Exports
  module Formatters
    module XLS
      module DateFormat
        DEFAULT_DATE = "YYYY-MM-DD"
        DEFAULT_TIME = "HH:MM"

        COMPOSITES = {
          "%F" => "%Y-%m-%d",
          "%D" => "%m/%d/%y",
          "%T" => "%H:%M:%S",
          "%R" => "%H:%M",
          "%r" => "%I:%M:%S %p"
        }.freeze

        DIRECTIVES = {
          "%%" => '"%"',
          "%-H" => "H",
          "%-I" => "H",
          "%-M" => "M",
          "%-S" => "S",
          "%-b" => "MMM",
          "%-d" => "D",
          "%-m" => "M",
          "%A" => "DDDD",
          "%B" => "MMMM",
          "%H" => "HH",
          "%I" => "HH",
          "%M" => "MM",
          "%P" => "AM/PM",
          "%S" => "SS",
          "%Y" => "YYYY",
          "%^B" => "MMMM",
          "%^b" => "MMM",
          "%_H" => "H",
          "%_I" => "H",
          "%_d" => "D",
          "%_m" => "M",
          "%a" => "DDD",
          "%b" => "MMM",
          "%d" => "DD",
          "%e" => "D",
          "%h" => "MMM",
          "%k" => "H",
          "%l" => "H",
          "%m" => "MM",
          "%p" => "AM/PM",
          "%y" => "YY"
        }.freeze

        TOKEN = /%[-_^#]?[a-zA-Z%]|[^%]+|%/
        UNQUOTED = %r{[^ \-/.,:]+}
        TWELVE_HOUR = /%[-_^#]?[Il]/
        MERIDIEM = /%[pP]/
        NUMERIC = /[0#]/

        module_function

        def date
          convert(date_pattern) || DEFAULT_DATE
        end

        def time
          convert(time_pattern) || DEFAULT_TIME
        end

        def datetime
          "#{date} #{time}"
        end

        def date_pattern
          Setting.date_format.presence || I18n.t("date.formats.default")
        end

        def time_pattern
          Setting.time_format.presence || I18n.t("time.formats.time")
        end

        def convert(pattern)
          pattern = COMPOSITES.reduce(pattern.to_s) { |expanded, (from, to)| expanded.gsub(from, to) }
          return if pattern.match?(TWELVE_HOUR) && !pattern.match?(MERIDIEM)

          format = translate(pattern)
          format unless format.nil? || format.match?(NUMERIC)
        end

        def translate(pattern)
          pattern.scan(TOKEN).map do |token|
            next quote_literals(token) unless token.start_with?("%")

            DIRECTIVES.fetch(token) { return nil }
          end.join
        end

        def quote_literals(text)
          text.gsub(UNQUOTED) { |run| %("#{run.delete('"')}") }
        end

        private_class_method :convert, :translate, :quote_literals, :date_pattern, :time_pattern
      end
    end
  end
end
