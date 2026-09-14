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
    # custom field to insert after (blank = top). Anchors are validated
    # against the target section before any mutation; source and target
    # section rows are locked in deterministic id order so concurrent
    # read-modify-write updates of attribute_order cannot lose each other.
    # The `raise ActiveRecord::Rollback unless moved` guard is defense-in-depth
    # for the cross-section branch (reparent already applied before the
    # insert is attempted); `requires_new: true` makes it an effective
    # savepoint even when nested inside a spec's outer transaction.
    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity -- validate, lock, and move is one linear flow
    def perform_anchor_drop(service_call, params)
      source_section = @custom_field.custom_field_section
      target_section = source_section.class.find_by(id: params[:list_id])
      return invalid_anchor(service_call) if target_section.nil?

      # Keep a single object identity for the same-row case so every read
      # and write below goes through the one instance that gets `lock!`ed.
      target_section = source_section if target_section.id == source_section.id

      section_changed = source_section.id != target_section.id
      moved = false

      CustomField.transaction(requires_new: true) do
        [source_section, target_section].uniq.sort_by(&:id).each(&:lock!)
        @custom_field.reload

        prev_key = anchor_key_in(target_section, params[:prev_id])
        if prev_key != :invalid && @custom_field.custom_field_section_id == source_section.id
          if section_changed
            source_section.remove_from_order(@custom_field.column_name)
            @custom_field.update!(custom_field_section_id: target_section.id)
          end
          moved = target_section.insert_after_key(@custom_field.column_name, prev_key)
        end

        raise ActiveRecord::Rollback unless moved
      end

      return invalid_anchor(service_call) unless moved

      service_call.success = true
      service_call.result = {
        section_changed:,
        current_section: target_section.reload,
        old_section: section_changed ? source_section.reload : nil
      }
      service_call
    end
    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

    # nil anchors the top; :invalid rejects the move. A valid anchor is a
    # different custom field already ordered in the target section.
    def anchor_key_in(target_section, prev_id)
      return nil if prev_id.blank?
      return :invalid if prev_id.to_i == @custom_field.id

      anchor = target_section.custom_fields.find_by(id: prev_id)
      return :invalid if anchor.nil? || target_section.attribute_order.exclude?(anchor.column_name)

      anchor.column_name
    end

    def invalid_anchor(service_call)
      service_call.success = false
      service_call.errors = I18n.t(:error_invalid_list_move_anchor)
      service_call
    end
  end
end
