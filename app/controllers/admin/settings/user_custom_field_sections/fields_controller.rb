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

module Admin
  module Settings
    module UserCustomFieldSections
      class FieldsController < ::Admin::SettingsController
        include OpTurbo::ComponentStream
        include FlashMessagesOutputSafetyHelper
        include Admin::Settings::UserCustomFields::ComponentStreams
        include ::SortableLists::DropRequestValidation

        menu_item :user_custom_fields_settings

        configure_drop_request list_type: "user_field", list_id_scoped: true

        def drop
          return render_invalid_drop_request unless valid_drop_request?

          result = drop_service.call(list_id: drop_params[:list_id], prev_id: drop_params[:prev_id])

          if result.success?
            drop_success_streams(result)
            respond_with_turbo_streams
          else
            render_error_flash_message_via_turbo_stream(message: join_flash_messages(result.errors))
            respond_with_turbo_streams(status: :unprocessable_entity)
          end
        end

        private

        def drop_service
          ::UserCustomFieldSections::DropService.new(user: current_user, key: params.expect(:key))
        end

        def render_invalid_drop_request
          render_error_flash_message_via_turbo_stream(message: I18n.t(:error_invalid_list_move_anchor))
          respond_with_turbo_streams(status: :unprocessable_entity)
        end

        def drop_success_streams(call)
          update_section_via_turbo_stream(user_custom_field_section: call.result[:current_section])
          if call.result[:section_changed]
            update_section_via_turbo_stream(user_custom_field_section: call.result[:old_section])
          end
        end
      end
    end
  end
end
