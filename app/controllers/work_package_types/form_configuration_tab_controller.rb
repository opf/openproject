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
  class FormConfigurationTabController < BaseTabController
    include TypesHelper
    include OpTurbo::ComponentStream
    include WorkPackageTypes::FormConfigurationComponentStreams

    layout "admin"

    current_menu_item [:edit, :update, :reset_dialog, :move, :drop, :destroy] do
      :types
    end

    def edit; end

    def reset_dialog
      respond_with_dialog(
        WorkPackageTypes::FormConfiguration::ResetDialogComponent.new(type: @type)
      )
    end

    def update
      result = WorkPackageTypes::UpdateService
        .new(user: current_user, model: @type, contract_class: UpdateFormConfigurationContract)
        .call(permitted_type_params)

      if result.success?
        respond_to_update_success
      else
        respond_to_update_failure(result)
      end
    end

    def move
      call = ::WorkPackageTypes::FormConfigurationRows::UpdateService
        .new(user: current_user, type: @type, row_key: row_key_param)
        .call(move_to: params[:move_to])

      handle_row_update_response(call)
    end

    def drop
      call = ::WorkPackageTypes::FormConfigurationRows::UpdateService
        .new(user: current_user, type: @type, row_key: row_key_param)
        .call(target_id: params[:target_id], position: params[:position])

      handle_row_update_response(call)
    end

    def destroy
      call = ::WorkPackageTypes::FormConfigurationRows::DeleteService
        .new(user: current_user, type: @type, row_key: row_key_param)
        .call

      handle_row_update_response(call)
    end

    private

    def respond_to_update_success
      respond_to do |format|
        format.html { redirect_to edit_type_form_configuration_path(@type), notice: t(:notice_successful_update) }
        format.turbo_stream do
          update_form_configuration_via_turbo_stream
          respond_with_turbo_streams
        end
      end
    end

    def respond_to_update_failure(result)
      respond_to do |format|
        format.html do
          flash.now[:error] = result.errors[:attribute_groups].to_sentence
          render :edit, status: :unprocessable_entity
        end
        format.turbo_stream { head :unprocessable_entity }
      end
    end

    def handle_row_update_response(call)
      if call.success?
        update_form_configuration_via_turbo_stream
      else
        render_form_configuration_error(call)
      end

      respond_with_turbo_streams(status: call.success? ? :ok : :unprocessable_entity)
    end

    def find_type
      @type = ::Type.includes(:projects, :custom_fields).find(params[:type_id])
      show_error_not_found unless @type
    end

    def row_key_param
      params[:row_key] || params[:id]
    end

    def permitted_type_params
      # having to call #to_unsafe_h as a query hash the attribute_groups
      # parameters would otherwise still be an ActiveSupport::Parameter
      permitted_params.type.to_unsafe_h
    end
  end
end
