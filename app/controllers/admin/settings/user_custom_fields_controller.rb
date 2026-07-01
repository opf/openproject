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

module Admin::Settings
  class UserCustomFieldsController < ::Admin::SettingsController
    include CustomFields::SharedActions
    include CustomFields::AttributeHelpTextActions
    include OpTurbo::ComponentStream
    include FlashMessagesOutputSafetyHelper
    include Admin::Settings::UserCustomFields::ComponentStreams

    menu_item :user_custom_fields_settings

    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :set_sections, only: %i[show index edit update move drop]
    before_action :find_custom_field,
                  only: %i(show edit update destroy delete_option reorder_alphabetical
                           move drop attribute_help_text update_attribute_help_text list_items)
    before_action :prepare_custom_option_position, only: %i(update create)
    before_action :find_custom_option, only: :delete_option
    before_action :find_or_initialize_attribute_help_text, only: %i[attribute_help_text update_attribute_help_text]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    def index
      @allow_custom_field_creation = @user_custom_field_sections.any?

      if params[:tab] == "semantic_keys"
        @semantic_key_field_options = UserCustomField.order(:position)
        @semantic_key_assignments = UserCustomField.where.not(semantic_key: nil).index_by(&:semantic_key)
      end

      respond_to :html
    end

    # Assigns (or clears) the custom field bound to each semantic key. Driven by
    # the "Semantic keys" tab on the index page rather than the per-field form, so
    # admins manage the mapping in one place. Clearing the previous holder before
    # setting the new one keeps the per-(type, semantic_key) unique index satisfied.
    def update_semantic_keys
      assign_semantic_keys

      flash[:notice] = t(:notice_successful_update)
      redirect_to admin_settings_user_custom_fields_path(tab: :semantic_keys)
    end

    def show
      render :edit
    end

    def new
      @custom_field = UserCustomField.new(custom_field_section_id: params[:custom_field_section_id],
                                          field_format: params[:field_format])

      respond_to :html
    end

    def edit; end

    def list_items; end

    def move
      result = CustomFields::MoveService.new(user: current_user, custom_field: @custom_field).call(
        move_to: params.expect(:move_to)
      )

      if result.success?
        update_sections_via_turbo_stream(user_custom_field_sections: @user_custom_field_sections)
      else
        render_error_flash_message_via_turbo_stream(
          message: join_flash_messages(result.errors)
        )
      end

      respond_with_turbo_streams
    end

    def drop
      result = CustomFields::DropService.new(user: current_user, custom_field: @custom_field).call(
        target_id: params[:target_id],
        position: params[:position]
      )

      if result.success?
        drop_success_streams(result)
      else
        render_error_flash_message_via_turbo_stream(
          message: join_flash_messages(result.errors)
        )
      end

      respond_with_turbo_streams
    end

    def destroy
      result = CustomFields::DeleteService.new(user: current_user, model: @custom_field).call

      if result.success?
        update_section_via_turbo_stream(user_custom_field_section: @custom_field.user_custom_field_section.reload)
      else
        render_error_flash_message_via_turbo_stream(
          message: join_flash_messages(result.errors)
        )
      end

      respond_with_turbo_streams
    end

    def attribute_help_text
      render_attribute_help_text_form
    end

    def update_attribute_help_text
      update_help_text
    end

    private

    def assign_semantic_keys
      UserCustomField.transaction do
        UserCustomField.semantic_keys.each_key do |key|
          custom_field_id = params.dig(:semantic_keys, key).presence

          UserCustomField.with_semantic_key(key).where.not(id: custom_field_id).update_all(semantic_key: nil)
          UserCustomField.where(id: custom_field_id).update_all(semantic_key: key) if custom_field_id
        end
      end
    end

    def set_sections
      @user_custom_field_sections = UserCustomFieldSection.includes(:custom_fields).all
    end

    def find_custom_field
      @custom_field = UserCustomField.find(params.expect(:id))
    end

    def drop_success_streams(call)
      update_section_via_turbo_stream(user_custom_field_section: call.result[:current_section])
      if call.result[:section_changed]
        update_section_via_turbo_stream(user_custom_field_section: call.result[:old_section])
      end
    end

    def show_path
      attribute_help_text_admin_settings_user_custom_field_path(@custom_field)
    end

    def render_attribute_help_text_form(status: :ok)
      render "custom_fields/attribute_help_texts/show_user", status:
    end
  end
end
