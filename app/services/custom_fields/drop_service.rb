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
      return ServiceResult.failure(errors: { base: :error_unauthorized }) unless @user.admin?

      perform_anchor_drop
    end

    private

    # The sortable-lists wire: list_id names the target section, prev_id the
    # custom field to insert after (blank = top).
    def perform_anchor_drop
      target_section = @custom_field.custom_field_section.class.find_by(id: params[:list_id])
      return invalid_anchor if target_section.nil?

      prev_key = anchor_key_in(target_section, params[:prev_id])
      return invalid_anchor if prev_key == :invalid

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

    def invalid_anchor
      ServiceResult.failure(errors: I18n.t(:error_invalid_list_move_anchor))
    end
  end
end
