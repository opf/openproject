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

module Exports::PDF::Components::Gantt
  class TextColumns
    MAX_COLUMNS = 6
    DEFAULT_COLUMN_NAMES = %w[id subject start_date due_date].freeze
    FALLBACK_COLUMN_NAMES = %w[subject].freeze

    EXCLUDED_SELECT_CLASS_NAMES = %w[
      Queries::WorkPackages::Selects::RelationSelect
      Bim::Queries::WorkPackages::Selects::BcfThumbnailSelect
    ].freeze
    FIXED_COLUMN_TYPES = %i[date datetime integer float decimal boolean].freeze
    FIXED_COMPUTED_COLUMN_NAMES = %w[spent_hours material_costs labor_costs overall_costs].freeze
    FIXED_CUSTOM_FIELD_FORMATS = %w[int float date datetime bool calculated_value].freeze

    attr_reader :query

    def initialize(query)
      @query = query
    end

    def available
      @available ||= query.displayable_columns.select { |column| allowed?(column) }
    end

    def allowed?(column)
      return false if excluded_select?(column)

      !custom_field_column?(column) || column.custom_field.field_format != "text"
    end

    def kind(column)
      return unless allowed?(column)
      return :subject if column.name == :subject

      fixed?(column) ? :fixed : :simple_text
    end

    def resolve(column_names)
      return defaults if column_names.nil?

      columns = find_columns(Array(column_names)).first(MAX_COLUMNS)
      columns.presence || find_columns(FALLBACK_COLUMN_NAMES)
    end

    def defaults
      find_columns(DEFAULT_COLUMN_NAMES)
    end

    private

    def find_columns(column_names)
      column_names
        .map(&:to_s)
        .uniq
        .filter_map { |name| available.find { |column| column.name.to_s == name } }
    end

    def excluded_select?(column)
      column.class.ancestors.any? { |ancestor| EXCLUDED_SELECT_CLASS_NAMES.include?(ancestor.name) }
    end

    def custom_field_column?(column)
      column.is_a?(Queries::WorkPackages::Selects::CustomFieldSelect)
    end

    def fixed?(column)
      if custom_field_column?(column)
        FIXED_CUSTOM_FIELD_FORMATS.include?(column.custom_field.field_format)
      else
        FIXED_COMPUTED_COLUMN_NAMES.include?(column.name.to_s) ||
          FIXED_COLUMN_TYPES.include?(WorkPackage.columns_hash[column.name.to_s]&.type)
      end
    end
  end
end
