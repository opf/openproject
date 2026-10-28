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

module SquashTMIntegration
  module Admin
    class ServersController < ApplicationController
      include OpTurbo::ComponentStream

      layout "admin"
      menu_item :admin_squashtm_integration

      before_action :require_admin
      before_action :set_server
      before_action :require_persisted_server, only: %i[test_connection destroy_dialog destroy]

      def show; end

      def update
        result = save_service.call(server_params)

        if result.success?
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to squashtm_integration_admin_server_path, status: :see_other
        else
          @server = result.result
          render :show, status: :unprocessable_entity
        end
      end

      def test_connection
        errors = ActiveModel::Errors.new(@server)
        ConnectionCheck.new(base_url: @server.base_url, api_token: @server.api_token).call(errors)

        if errors.empty?
          flash[:notice] = t(".success")
        else
          flash[:error] = t(".failure", reason: errors.full_messages.to_sentence)
        end

        redirect_to squashtm_integration_admin_server_path, status: :see_other
      end

      def destroy_dialog
        respond_with_dialog DeleteServerDialogComponent.new(@server)
      end

      def destroy
        result = Servers::DeleteService.new(user: current_user, model: @server).call

        if result.success?
          flash[:notice] = I18n.t(:notice_successful_delete)
        else
          flash[:error] = result.errors.full_messages.to_sentence
        end

        redirect_to squashtm_integration_admin_server_path, status: :see_other
      end

      private

      def set_server
        @server = Server.current
      end

      def require_persisted_server
        render_404 unless @server.persisted?
      end

      def save_service
        if @server.persisted?
          Servers::UpdateService.new(user: current_user, model: @server)
        else
          Servers::CreateService.new(user: current_user)
        end
      end

      def server_params
        permitted = params.expect(squashtm_server: %i[base_url api_token]).to_h.symbolize_keys
        permitted.delete(:api_token) if permitted[:api_token].blank?
        permitted
      end
    end
  end
end
