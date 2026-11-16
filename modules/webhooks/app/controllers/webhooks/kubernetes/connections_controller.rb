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

module Webhooks
  module Kubernetes
    class ConnectionsController < ::ApplicationController
      layout "admin"

      before_action :require_admin
      before_action :find_connection, only: %i[edit update destroy test]

      menu_item :plugin_webhooks_kubernetes_connections

      def index
        @connections = ::Webhooks::KubernetesConnection.order(:name)
      end

      def new
        @connection = ::Webhooks::KubernetesConnection.new(verify_tls: true)
      end

      def edit; end

      def create
        @connection = ::Webhooks::KubernetesConnection.new(permitted_params)
        if @connection.save
          flash[:notice] = I18n.t(:notice_successful_create)
          redirect_to edit_admin_kubernetes_connection_path(@connection)
        else
          render action: :new, status: :unprocessable_entity
        end
      end

      def update
        attributes = permitted_params
        if @connection.update(attributes.except(*%i[token client_key].select { attributes[it].blank? }))
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to edit_admin_kubernetes_connection_path(@connection)
        else
          render action: :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @connection.destroy
          flash[:notice] = I18n.t(:notice_successful_delete)
        else
          flash[:error] = @connection.errors.full_messages.join(" ")
        end
        redirect_to admin_kubernetes_connections_path, status: :see_other
      end

      def test
        success, message = @connection.test_connection
        flash[success ? :notice : :error] = message
        redirect_to edit_admin_kubernetes_connection_path(@connection), status: :see_other
      end

      private

      def find_connection
        @connection = ::Webhooks::KubernetesConnection.find(params.expect(:id))
      end

      def permitted_params
        params
          .expect(kubernetes_connection: %i[name auth_mode api_url namespace verify_tls ca_cert token client_cert
                                            client_key openproject_url openproject_ca_cert])
      end
    end
  end
end
