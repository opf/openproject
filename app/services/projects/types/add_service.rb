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

module Projects
  module Types
    class AddService < BaseService
      private

      # A project applies one variant per type, so enabling a second is a conflict with
      # whatever that row already resolves to rather than a check per pair of variants.
      def persist(service_call)
        variant = params[:variant]
        current_project_type = model.project_types.find_by(type_id: variant.type_id)

        if current_project_type&.variant_id == variant.id
          service_call
        elsif named_variant_without_feature?(variant)
          failure(:cannot_assign_variants_yet)
        elsif current_project_type
          failure(conflict_with(current_project_type, variant))
        else
          add_variant(variant)
          service_call
        end
      end

      def conflict_with(current_project_type, variant)
        if variant.is_default_variant? || current_project_type.variant.is_default_variant?
          :cannot_assign_variant_and_parent
        else
          :cannot_assign_multiple_variants_of_parent
        end
      end

      def named_variant_without_feature?(variant)
        !variant.is_default_variant? && !OpenProject::FeatureDecisions.type_variants_active?
      end

      def add_variant(variant)
        model.project_types.create!(type_id: variant.type_id, variant:)
        enable_work_package_custom_fields(variant)
      end
    end
  end
end
