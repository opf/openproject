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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  module Admin
    class OAuthClientsController < ApplicationController
      include OpTurbo::ComponentStream
      include Concerns::WizardNavigation

      layout "admin"

      before_action :require_admin
      before_action :find_wiki_provider

      menu_item :wiki_providers

      def new
        oauth_client = OAuthClient.new(
          client_id: Wikis::XWikiProvider.generate_client_id,
          client_secret: Wikis::XWikiProvider.generate_client_secret
        )

        update_via_turbo_stream(
          component: Wikis::Admin::Forms::OAuthClientFormComponent.new(@wiki_provider,
                                                                       oauth_client:,
                                                                       in_wizard: in_wizard?)
        )
        respond_with_turbo_streams
      end

      def create
        save_oauth_client

        @service_result.on_failure do
          update_via_turbo_stream(
            component: Wikis::Admin::Forms::OAuthClientFormComponent.new(@wiki_provider,
                                                                         oauth_client: @oauth_client,
                                                                         in_wizard: in_wizard?)
          )
          respond_with_turbo_streams
        end

        @service_result.on_success { respond_for_success }
      end

      def update
        save_oauth_client

        @service_result.on_failure do
          update_via_turbo_stream(
            component: Wikis::Admin::Forms::OAuthClientFormComponent.new(@wiki_provider,
                                                                         oauth_client: @oauth_client)
          )
          respond_with_turbo_streams
        end

        @service_result.on_success { respond_for_success }
      end

      private

      def save_oauth_client
        @service_result = Wikis::OAuthClients::CreateService
                            .new(user: current_user)
                            .call(oauth_client_params.merge(integration: @wiki_provider))
        @oauth_client = @service_result.result
        @wiki_provider.reload
      end

      def oauth_client_params
        params.expect(oauth_client: %i[client_id client_secret])
      end

      def find_wiki_provider
        @wiki_provider = Wikis::Provider.visible.find(params[:wiki_provider_id])
      end

      def respond_for_success
        if in_wizard?
          redirect_to new_admin_settings_wiki_provider_path(continue_wizard: @wiki_provider.id), status: :see_other
        else
          update_via_turbo_stream(component: Wikis::Admin::OAuthClientInfoComponent.new(@wiki_provider))
          respond_with_turbo_streams
        end
      end
    end
  end
end
