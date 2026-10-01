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

module Queries
  # Renders a set of query filters as human-readable text, e.g.
  # ["Job title is Developer", "Spoken language is German, English"].
  #
  #   Queries::FilterSummary.new(query.filters).phrases
  #   Queries::FilterSummary.new(placeholder_user.user_filter).to_s
  #
  # List filters (custom fields, status, …) have their value ids resolved to the
  # corresponding objects; other filters fall back to their raw values. A filter
  # without values, or one that cannot describe itself, is skipped so a malformed
  # stored filter never breaks rendering.
  class FilterSummary
    DEFAULT_SEPARATOR = " · "

    def initialize(filters)
      @filters = Array(filters)
    end

    # @return [Array<String>] one phrase per describable filter
    def phrases
      @filters.filter_map { |filter| describe(filter) }
    end

    # @return [String] all phrases joined for inline display
    def to_s(separator: DEFAULT_SEPARATOR)
      phrases.join(separator)
    end

    delegate :empty?, to: :phrases

    private

    def describe(filter)
      values = value_labels(filter)
      return if values.blank?

      "#{filter.human_name} #{filter.operator_class.human_name} #{values}"
    rescue StandardError
      nil
    end

    def value_labels(filter)
      labels = filter.ar_object_filter? ? filter.value_objects.map(&:to_s) : Array(filter.values)
      labels.compact_blank.join(", ")
    end
  end
end
