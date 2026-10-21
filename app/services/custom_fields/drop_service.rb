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

module CustomFields
  class DropService < ::BaseServices::BaseCallable
    def initialize(user:, custom_field:)
      super()
      @user = user
      @custom_field = custom_field
    end

    def perform
      service_call = validate_permissions
      if service_call.success?
        service_call = if params.key?(:prev_id)
                         perform_anchor_drop(service_call, params)
                       else
                         perform_drop(service_call, params)
                       end
      end
      service_call
    end

    def validate_permissions
      if @user.admin?
        ServiceResult.success
      else
        ServiceResult.failure(errors: { base: :error_unauthorized })
      end
    end

    def perform_drop(service_call, params)
      section_changed, current_section, old_section = move_to_target_section(params)
      current_section.add_to_order(@custom_field.column_name, position: params[:position]&.to_i)

      service_call.success = true
      service_call.result = { section_changed:, current_section: current_section.reload, old_section: }
      service_call
    rescue StandardError => e
      service_call.success = false
      service_call.errors = e.message
      service_call
    end

    private

    def move_to_target_section(params)
      current_section = @custom_field.custom_field_section
      new_section_id = params[:target_id]&.to_i

      return [false, current_section, nil] if current_section.id == new_section_id

      old_section = current_section
      current_section = CustomFieldSection.find(new_section_id)
      old_section.remove_from_order(@custom_field.column_name)
      @custom_field.update!(custom_field_section_id: current_section.id)

      [true, current_section, old_section.reload]
    end

    # The sortable-lists wire: list_id names the target section, prev_id the
    # custom field to insert after (blank = top).
    def perform_anchor_drop(service_call, params)
      target_section = @custom_field.custom_field_section.class.find_by(id: params[:list_id])
      return invalid_anchor(service_call) if target_section.nil?

      prev_key = anchor_key_in(target_section, params[:prev_id])
      return invalid_anchor(service_call) if prev_key == :invalid

      CustomFieldSections::MoveKeyService
        .new(key: @custom_field.column_name,
             from: @custom_field.custom_field_section,
             to: target_section,
             custom_field: @custom_field)
        .call(prev_key:)
    end

    # nil anchors the top; :invalid rejects the move.
    def anchor_key_in(target_section, prev_id)
      return nil if prev_id.blank?

      target_section.custom_fields.find_by(id: prev_id)&.column_name || :invalid
    end

    def invalid_anchor(service_call)
      service_call.success = false
      service_call.errors = I18n.t(:error_invalid_list_move_anchor)
      service_call
    end
  end
end
