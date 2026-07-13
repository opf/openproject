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
      # Pass +project:+ to restrict the check to a single known project instead of
      # scanning all projects visible to the user.
      def on_visible_type_and_project(user = User.current, project: nil)
        visible_projects = Project.visible(user)
        visible_projects = visible_projects.where(id: project.id) if project&.persisted?

        where(<<~SQL.squish)
          EXISTS (
            SELECT 1
            FROM (#{visible_projects.select(:id).to_sql}) vp
            JOIN projects_types pt
              ON pt.project_id = vp.id
            JOIN custom_fields_types cft
              ON cft.type_id = pt.type_id
             AND cft.custom_field_id = custom_fields.id
            LEFT JOIN custom_fields_projects cfp
              ON cfp.project_id = vp.id
             AND cfp.custom_field_id = custom_fields.id
            WHERE custom_fields.is_for_all = TRUE
               OR cfp.custom_field_id IS NOT NULL
          )
        SQL
      end
    end
  end
end
