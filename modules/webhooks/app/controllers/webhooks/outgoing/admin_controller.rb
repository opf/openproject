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
  module Outgoing
    class AdminController < ::ApplicationController
      layout "admin"

      before_action :require_admin
      before_action :find_webhook, only: %i[show edit update destroy]

      menu_item :plugin_webhooks

      def index
        @webhooks = webhook_class.all
      end

      def show; end

      def edit; end

      def new
        @webhook = webhook_class.new_default
      end

      def create
        service = ::Webhooks::Outgoing::UpdateWebhookService.new(webhook_class.new_default, current_user:)
        action = service.call(attributes: permitted_webhooks_params)
        if action.success?
          flash[:notice] = I18n.t(:notice_successful_create)
          redirect_to action: :index
        else
          @webhook = action.result
          render action: :new, status: :unprocessable_entity
        end
      end

      def update
        service = ::Webhooks::Outgoing::UpdateWebhookService.new(@webhook, current_user:)
        action = service.call(attributes: permitted_webhooks_params)
        if action.success?
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to action: :index
        else
          @webhook = action.result
          render action: :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @webhook.destroy
          flash[:notice] = I18n.t(:notice_successful_delete)
        else
          flash[:error] = I18n.t(:error_failed_to_delete_entry)
        end

        redirect_to action: :index, status: :see_other
      end

      private

      def find_webhook
        @webhook = webhook_class.find(params[:webhook_id])
      end

      def webhook_class
        ::Webhooks::Webhook
      end

      def permitted_webhooks_params
        params
          .require(:webhook)
          .permit(:name, :description, :url, :secret, :enabled,
                  :project_ids, selected_project_ids: [], events: [])
      end
    end
  end
end
