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
  module FormConfigurationRows
    class MoveService < ::WorkPackageTypes::FormConfiguration::BaseMoveService
      SortableTypes = ::WorkPackageTypes::FormConfiguration::SortableTypes

      private

      def fresh_record
        form_configuration.form_attributes.find_by(id: @record.id)
      end

      def move(membership)
        case params[:list_type]
        when SortableTypes::INACTIVE_ATTRIBUTE then deactivate(membership)
        when SortableTypes::ATTRIBUTE then place(membership)
        else invalid_move
        end
      end

      def deactivate(membership)
        return invalid_move if params[:list_id].present?

        membership.deactivate!
        ServiceResult.success(result: membership)
      end

      def place(membership)
        group = target_group
        return invalid_move if group.nil? || !params.key?(:prev_id) || !offered?(membership)

        placed?(membership, group) ? ServiceResult.success(result: membership) : invalid_move
      end

      def placed?(membership, group)
        if membership.form_configuration_group_id == group.id
          return membership.move_after_anchor(params[:prev_id], scope: group.members)
        end

        position = membership.position_after_anchor(params[:prev_id], scope: group.members)
        return false if position.nil?

        membership.place!(group:, position:)
        true
      end

      def target_group
        id = Lists::MoveAfterAnchor.canonical_id(params[:list_id])

        form_configuration.form_groups.kind_attribute.find_by(id:) if id
      end

      def offered?(membership)
        form_configuration.work_package_attributes.key?(membership.key)
      end
    end
  end
end
