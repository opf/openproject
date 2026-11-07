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

module UserCustomFieldSections
  # Drops a "user_field" row, keyed either by a UserCustomField id or by a
  # BUILT_IN_ATTRIBUTES name. Built-in attributes own no record, so their
  # source section is the one whose attribute_order lists them.
  class DropService < ::BaseServices::BaseCallable
    CUSTOM_FIELD_ID = /\A\d+\z/

    def initialize(user:, key:)
      super()
      @user = user
      @key = key.to_s
    end

    def perform
      return ServiceResult.failure(errors: { base: :error_unauthorized }) unless @user.admin?

      perform_anchor_drop
    end

    private

    def perform_anchor_drop
      return invalid_anchor unless order_key && source_section && target_section

      prev_key = anchor_key_in(params[:prev_id])
      return invalid_anchor if prev_key == :invalid

      CustomFieldSections::MoveKeyService
        .new(key: order_key, from: source_section, to: target_section, custom_field:)
        .call(prev_key:)
    end

    def custom_field
      return @custom_field if defined?(@custom_field)

      @custom_field = (UserCustomField.find_by(id: @key) if @key.match?(CUSTOM_FIELD_ID))
    end

    def order_key
      custom_field&.column_name || built_in_key(@key)
    end

    def source_section
      return @source_section if defined?(@source_section)

      @source_section = custom_field&.custom_field_section ||
                        UserCustomFieldSection.find_by("? = ANY(attribute_order)", order_key)
    end

    def target_section
      return @target_section if defined?(@target_section)

      @target_section = UserCustomFieldSection.find_by(id: params[:list_id])
    end

    # nil anchors the top; :invalid rejects the move.
    def anchor_key_in(prev_id)
      return nil if prev_id.blank?

      anchor_field = target_section.custom_fields.find_by(id: prev_id) if prev_id.to_s.match?(CUSTOM_FIELD_ID)
      anchor_field&.column_name || built_in_key(prev_id) || :invalid
    end

    def built_in_key(key)
      key.to_s if UserCustomFieldSection::BUILT_IN_ATTRIBUTES.include?(key.to_s)
    end

    def invalid_anchor
      ServiceResult.failure(errors: I18n.t(:error_invalid_list_move_anchor))
    end
  end
end
