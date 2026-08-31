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

module WorkPackageTypes
  module CopyConfiguration
    class ProjectAttributesService < BaseService
      private

      def aspect = TypeVariant::PROJECT_ATTRIBUTES

      # Adopts the source's mappings minus the ones the variant's link chain excludes: going
      # Independent has to keep the configuration the variant was presenting, not silently
      # re-enable the attributes it was hiding. Runs before the link is severed, so the
      # exclusions are still readable here.
      def copy_from(source)
        custom_field_ids = source.own_project_custom_field_type_mappings.pluck(:custom_field_id) -
                           variant.excluded_custom_field_ids(aspect)

        ProjectCustomFieldTypeMapping.transaction do
          variant.own_project_custom_field_type_mappings.delete_all
          next if custom_field_ids.empty?

          variant.own_project_custom_field_type_mappings.insert_all(
            custom_field_ids.map { |id| { custom_field_id: id } },
            unique_by: %i[type_variant_id custom_field_id]
          )
        end
      end
    end
  end
end
