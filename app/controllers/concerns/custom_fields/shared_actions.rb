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
  module SharedActions
    extend ActiveSupport::Concern

    included do
      def index_path(custom_field, params = {})
        case custom_field.type
        when "ProjectCustomField"
          admin_settings_project_custom_fields_path(**params)
        when "UserCustomField"
          admin_settings_user_custom_fields_path(**params)
        else
          custom_fields_path(**params)
        end
      end

      def edit_path(custom_field, params = {})
        case custom_field.type
        when "ProjectCustomField"
          admin_settings_project_custom_field_path(**params)
        when "UserCustomField"
          edit_admin_settings_user_custom_field_path(**params)
        else
          edit_custom_field_path(**params)
        end
      end

      def create # rubocop:disable Metrics/AbcSize
        call = ::CustomFields::CreateService
          .new(user: current_user)
          .call(get_custom_field_params.merge(type: permitted_params.custom_field_type))

        if call.success?
          custom_field = call.result
          flash[:notice] = t(:notice_successful_create)
          call_hook(:controller_custom_fields_new_after_save, custom_field:)
          redirect_to edit_path(custom_field, id: custom_field.id)
        else
          @custom_field = call.result || new_custom_field
          render action: :new, status: :unprocessable_entity
        end
      end

      def update
        perform_update(get_custom_field_params)
      end

      def perform_update(custom_field_params) # rubocop:disable Metrics/AbcSize
        call = ::CustomFields::UpdateService
          .new(user: current_user, model: @custom_field)
          .call(custom_field_params)

        if call.success?
          flash[:notice] = t(:notice_successful_update)
          call_hook(:controller_custom_fields_edit_after_save, custom_field: @custom_field)

          redirect_to(edit_path(@custom_field, id: @custom_field.id))
        else
          flash.now[:error] = I18n.t(:notice_unsuccessful_update_with_reason, reason: call.message)
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        begin
          @custom_field.destroy
        rescue StandardError
          flash[:error] = I18n.t(:error_can_not_delete_custom_field)
        end
        redirect_to index_path(@custom_field, tab: @custom_field.class.name), status: :see_other
      end

      def new_custom_field
        field = ::CustomFields::CreateService.careful_new_custom_field(permitted_params.custom_field_type)
        field.field_format = params[:field_format]
        field
      end

      def get_custom_field_params
        permitted_params.custom_field
      end
    end
  end
end
