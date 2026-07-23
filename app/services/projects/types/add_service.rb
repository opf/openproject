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

      def persist(service_call)
        type = params[:type]

        if model.types.include?(type)
          service_call
        elsif variant_without_feature?(type)
          failure(:cannot_assign_variants_yet)
        elsif sibling_variant_enabled?(type)
          failure(:cannot_assign_multiple_variants_of_parent)
        elsif family_conflict?(type)
          failure(:cannot_assign_variant_and_parent)
        else
          add_type(type)
          service_call
        end
      end

      def variant_without_feature?(type)
        type.variant? && !OpenProject::FeatureDecisions.type_variants_active?
      end

      def sibling_variant_enabled?(type)
        return false unless type.variant?

        model.types.exists?(parent_id: type.parent_id)
      end

      # A variant may not be enabled alongside its parent, and vice versa.
      def family_conflict?(type)
        if type.variant?
          model.types.exists?(id: type.parent_id)
        else
          model.types.exists?(parent_id: type.id)
        end
      end

      def add_type(type)
        model.types << type
        enable_work_package_custom_fields(type)
      end
    end
  end
end
