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

module WorkPackageTypes
  module FormConfigurationAttributes
    class MoveService < ::WorkPackageTypes::FormConfiguration::BaseMoveService
      SortableTypes = ::WorkPackageTypes::FormConfiguration::SortableTypes

      private

      def fresh_record
        form_configuration.form_attributes.find_by(id: @record.id)
      end

      def move(attribute)
        case params[:list_type]
        when SortableTypes::INACTIVE_ATTRIBUTE then deactivate(attribute)
        when SortableTypes::ATTRIBUTE then place(attribute)
        else invalid_move
        end
      end

      def deactivate(attribute)
        return invalid_move if params[:list_id].present?

        attribute.deactivate!
        ServiceResult.success(result: attribute)
      end

      def place(attribute)
        group = target_group
        return invalid_move if group.nil? || !params.key?(:prev_id) || !offered?(attribute)

        placed?(attribute, group) ? ServiceResult.success(result: attribute) : invalid_move
      end

      def placed?(attribute, group)
        if attribute.form_configuration_group_id == group.id
          return attribute.move_after_anchor(params[:prev_id], scope: group.form_attributes)
        end

        position = attribute.position_after_anchor(params[:prev_id], scope: group.form_attributes)
        return false if position.nil?

        attribute.place!(group:, position:)
        true
      end

      def target_group
        id = Lists::MoveAfterAnchor.canonical_id(params[:list_id])

        form_configuration.form_groups.kind_attribute.find_by(id:) if id
      end

      def offered?(attribute)
        form_configuration.work_package_attributes.key?(attribute.key)
      end
    end
  end
end
