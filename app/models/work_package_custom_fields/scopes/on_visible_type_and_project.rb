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

module WorkPackageCustomFields::Scopes
  module OnVisibleTypeAndProject
    extend ActiveSupport::Concern

    class_methods do
      # Returns custom fields that are defined for visible types and projects.
      #
      # For a custom field to be returned, it will have to be defined:
      # * on a type which in turn is active in a project the user has access to
      # * on a project the user has access to
      # Both conditions need to be met on the same project.
      #
      # A type whose form configuration is linked resolves to the type that
      # actually owns that configuration, so its work packages surface the
      # source type's fields.
      #
      # Pass +project:+ to restrict the check to a single known project instead of
      # scanning all projects visible to the user.
      def on_visible_type_and_project(user = User.current, project: nil)
        visible_projects = Project.visible(user)
        visible_projects = visible_projects.where(id: project.id) if project&.persisted?

        source_join, source_type_id = effective_form_source_sql

        where(<<~SQL.squish)
          EXISTS (
            SELECT 1
            FROM (#{visible_projects.select(:id).to_sql}) vp
            JOIN projects_types pt
              ON pt.project_id = vp.id
            #{source_join}
            JOIN custom_fields_types cft
              ON cft.type_id = #{source_type_id}
             AND cft.custom_field_id = custom_fields.id
            LEFT JOIN custom_fields_projects cfp
              ON cfp.project_id = vp.id
             AND cfp.custom_field_id = custom_fields.id
            WHERE custom_fields.is_for_all = TRUE
               OR cfp.custom_field_id IS NOT NULL
          )
        SQL
      end

      private

      # Returns [join_sql, type_id_expression] used to key the custom_fields_types
      # join. When some type links its form configuration elsewhere, the join is
      # redirected through the link's terminal source; otherwise the physical
      # type is used unchanged.
      def effective_form_source_sql
        map = form_source_map
        return ["", "pt.type_id"] if map.empty?

        values = map.map { |type_id, source_id| "(#{type_id}, #{source_id})" }.join(", ")
        join = "LEFT JOIN (VALUES #{values}) AS effective(type_id, source_id) " \
               "ON effective.type_id = pt.type_id"
        [join, "COALESCE(effective.source_id, pt.type_id)"]
      end

      # Maps each type linking its form configuration to the id of the type that
      # owns it. Reuses Type#effective_source_for so the feature-flag gate and
      # cycle tolerance stay in one place; the map is empty (identity everywhere)
      # when the subtypes feature is off.
      def form_source_map
        aspect = Type::ConfigurationLink::FORM_CONFIGURATION
        linked_type_ids = Type::ConfigurationLink.where(aspect:).distinct.pluck(:type_id)

        Type.where(id: linked_type_ids)
            .to_h { |type| [type.id, type.effective_source_for(aspect).id] }
            .reject { |type_id, source_id| type_id == source_id }
      end
    end
  end
end
