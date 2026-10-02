# frozen_string_literal: true

# -- copyright
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
# ++

module Projects::Scopes
  module AvailableCustomFields
    extend ActiveSupport::Concern

    class_methods do
      def with_available_custom_fields(custom_field_ids)
        condition = available_custom_fields_condition(custom_field_ids)
        condition ? where(condition) : none
      end

      def without_available_custom_fields(custom_field_ids)
        where.not(id: with_available_custom_fields(custom_field_ids).select(:id))
      end

      def with_available_project_custom_fields(custom_field_ids)
        where(id: project_custom_fields_project_mapping_subquery(custom_field_ids:))
      end

      def without_available_project_custom_fields(custom_field_ids)
        where.not(id: project_custom_fields_project_mapping_subquery(custom_field_ids:))
      end

      private

      def available_custom_fields_condition(custom_field_ids)
        ids = Array(custom_field_ids).map { Integer(it) }
        return nil if ids.empty?

        form_join, form_configuration_id, excluded = TypeVariant.form_configuration_join("pt.variant_id")
        exclusion = TypeVariant.excluded_custom_field_condition("fca.custom_field_id", excluded)

        <<~SQL.squish
          EXISTS (
            SELECT 1
            FROM project_types pt
            #{form_join}
            JOIN form_configuration_attributes fca
              ON fca.form_configuration_id = #{form_configuration_id}
             AND fca.form_configuration_group_id IS NOT NULL
             AND fca.custom_field_id IN (#{ids.join(', ')})
             AND #{exclusion}
            WHERE pt.project_id = projects.id
          )
        SQL
      end

      def project_custom_fields_project_mapping_subquery(custom_field_ids:)
        ProjectCustomFieldProjectMapping.select(:project_id)
                                        .where(custom_field_id: custom_field_ids)
      end
    end
  end
end
