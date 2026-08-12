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
  module Concerns
    # Escape cells that begin with a spreadsheet formula-triggering character,
    # if the +csv_escape_formulas+ setting is active.
    module CSVFormulaSanitization
      module_function

      # Leading characters that always indicate a formula and will always be escaped
      ALWAYS_ESCAPE = %W[= @ \t \r].freeze

      # Leading characters that trigger formula evaluation but may also legitimately
      # be a number (negative/positive values).
      POSSIBLE_NUMBER_START = %w[- +].freeze

      # A single, optionally signed number as it appears in exported cells:
      # thousands/decimal separators, optional surrounding whitespace and an
      # optional currency symbol or percent sign (e.g. "-5.00", "-1.234,56 €").
      # Anything with an internal operator (e.g. "+1+1") or letters/parentheses
      # fails this match and will be treated as a formula again
      PLAIN_NUMBER = /\A[+-]?[\p{Sc}\s]*\d[\d.,'\s]*[\p{Sc}%]?\z/u

      # Escape a single CSV cell value if the setting is active
      #
      # @param value [Object] the raw cell value
      # @return [String] the (possibly escaped) string value
      def sanitize(value)
        str = value.to_s
        return str unless needs_escaping?(str)

        "'#{str}"
      end

      def needs_escaping?(str)
        return false unless Setting.csv_escape_formulas?
        return false if str.empty?

        first = str[0]
        return true if ALWAYS_ESCAPE.include?(first)
        return false unless POSSIBLE_NUMBER_START.include?(first)

        # Leading - or +: only escape when the value is not a plain signed number.
        !str.match?(PLAIN_NUMBER)
      end
    end
  end
end
