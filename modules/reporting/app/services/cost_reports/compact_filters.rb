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
module CostReports
  # Builds the compact filter syntax the url uses from operators and values,
  # whether those come from a report, a leftover session, or a link created back
  # when filters were passed as fields[]/operators[]/values[].
  class CompactFilters
    CUSTOM_FIELD = /\ACustomField(\d+)\z/i

    # The session keys these by symbol, request parameters by string.
    def initialize(operators:, values:, rows: [], columns: [])
      @operators = normalize(operators)
      @values = normalize(values)
      @rows = Array(rows)
      @columns = Array(columns)
    end

    def to_params
      { filters: filters_param, rows: axis(@rows), columns: axis(@columns) }.compact_blank
    end

    def any?
      @operators.any? || @rows.any? || @columns.any?
    end

    private

    def normalize(hash)
      case hash
      when ActionController::Parameters then hash.permit!.to_h.stringify_keys
      when Hash then hash.stringify_keys
      else {}
      end
    end

    def filters_param
      @operators.map { |name, operator| filter_string(name, operator) }.join(" & ")
    end

    def filter_string(name, operator)
      "#{attribute_for(name)} #{operator} #{quoted(Array(@values[name]))}".rstrip
    end

    # The engine addressed its filters by class name, e.g. WorkPackageId or
    # CustomField7, where the modern ones use the attribute.
    def attribute_for(name)
      match = CUSTOM_FIELD.match(name.to_s)

      match ? "cf_#{match[1]}" : name.to_s.underscore
    end

    def quoted(values)
      quoted = values.compact.map { |value| %("#{escaped(value)}") }

      return quoted.join if quoted.size <= 1

      "[#{quoted.join(',')}]"
    end

    def escaped(value)
      value.to_s.gsub(/[\\"]/) { |character| "\\#{character}" }
    end

    def axis(dimensions)
      Array(dimensions).map { |dimension| attribute_for(dimension) }.join(",")
    end
  end
end
