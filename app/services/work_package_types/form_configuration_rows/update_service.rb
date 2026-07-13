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
    class UpdateService < ::BaseServices::BaseCallable
      include ::WorkPackageTypes::FormConfiguration::Concern

      INACTIVE_TARGET = "inactive"

      def initialize(user:, type:, row_key:)
        super(user:, type:)
        @row_key = row_key
      end

      def perform
        return move_row(params[:move_to].to_sym) if move_requested?
        return drop_row(target_id: params[:target_id], position: params[:position]) if drop_requested?

        failure_with_message(I18n.t("types.edit.form_configuration.not_found"))
      end

      private

      def move_row(move_to)
        row = find_row(@row_key)
        return failure_with_message(I18n.t("types.edit.form_configuration.not_found")) unless row

        update_row_position(row, move_to)
        persist_group_result(row[:group])
      end

      def drop_row(target_id:, position:)
        row = find_row(@row_key)

        return drop_row_to_inactive(row) if inactive_target?(target_id)

        target_group = find_attribute_group(target_id)
        return failure_with_message(I18n.t("types.edit.form_configuration.not_found")) unless target_group

        move_row_to_target_group(row, target_group, position)
        persist_group_result(target_group)
      end

      def row_move_index(move_to, current_index:, size:)
        case move_to
        when :highest
          0
        when :higher
          [current_index - 1, 0].max
        when :lower
          [current_index + 1, size - 1].min
        when :lowest
          size - 1
        else
          current_index
        end
      end

      def inactive_target?(target_id)
        target_id.to_s == INACTIVE_TARGET
      end

      def drop_row_to_inactive(row)
        remove_row_from_source(row)
        persist_group_result(row&.dig(:group))
      end

      def move_requested?
        params[:move_to].present?
      end

      def drop_requested?
        params[:target_id].present?
      end

      def update_row_position(row, move_to)
        attributes = row[:group].attributes.dup
        current_index = row[:index]
        new_index = row_move_index(move_to, current_index:, size: attributes.length)

        attributes.insert(new_index, attributes.delete_at(current_index)) if new_index != current_index
        row[:group].attributes = attributes
      end

      def move_row_to_target_group(row, target_group, position)
        remove_row_from_source(row)
        target_attributes = target_group.attributes.dup
        target_attributes.insert(drop_insert_position(position, target_attributes), @row_key)
        target_group.attributes = target_attributes
      end

      def persist_group_result(group)
        persist_groups(active_groups).tap do |call|
          call.result = group if call.success?
        end
      end

      def remove_row_from_source(row)
        return unless row

        source_attributes = row[:group].attributes.dup
        source_attributes.delete_at(row[:index])
        row[:group].attributes = source_attributes
      end

      def drop_insert_position(position, target_attributes)
        [position.to_i - 1, 0].max.clamp(0, target_attributes.length)
      end
    end
  end
end
