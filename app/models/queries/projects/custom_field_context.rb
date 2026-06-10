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

module Queries::Projects::CustomFieldContext
  class << self
    def custom_field_class
      ::ProjectCustomField
    end

    def model
      ::Project
    end

    def customized_type
      model.name
    end

    def custom_fields(_context = nil)
      custom_field_class.visible
    end

    def find_custom_field(id)
      custom_field_cache.fetch(id.to_i) do |key|
        preload_custom_fields([key]).first
      end
    end

    def preload_custom_fields(ids) # rubocop:disable Metrics/AbcSize
      ids_to_load = ids.map(&:to_i) - custom_field_cache.keys

      if ids_to_load.any?
        found = custom_fields_eager_loaded
                  .where(id: ids_to_load)
                  .index_by(&:id)
        # Iterating over the ids_to_load will also cache missing custom fields
        # as nil, making sure we only try to load them once.
        ids_to_load.each { |id| custom_field_cache[id] = found[id] }
      end

      ids.filter_map { |id| custom_field_cache[id.to_i] }
    end

    def where_subselect_joins(custom_field)
      <<~SQL.squish
        LEFT OUTER JOIN #{cv_db_table}
          ON #{cv_db_table}.customized_type='Project'
          AND #{cv_db_table}.customized_id=#{project_db_table}.id
          AND #{cv_db_table}.custom_field_id=#{custom_field.id}
        INNER JOIN project_custom_field_project_mappings
          ON project_custom_field_project_mappings.project_id = #{project_db_table}.id
          AND project_custom_field_project_mappings.custom_field_id = #{custom_field.id}
      SQL
    end

    def where_subselect_conditions
      # Allow searching projects only with :view_project_attributes permission
      allowed_project_ids = Project.allowed_to(User.current, :view_project_attributes)
                                   .select(:id)
      <<~SQL.squish
        #{project_db_table}.id IN (#{allowed_project_ids.to_sql})
      SQL
    end

    private

    def custom_fields_eager_loaded = custom_fields.includes(:calculated_value_errors)
    def custom_field_cache = RequestStore.fetch("Queries::Projects::CustomFieldContext/cache") { {} }
    def cv_db_table = CustomValue.table_name
    def project_db_table = Project.table_name
  end
end
