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
  class XWikiEnvSyncService < EnvSyncService
    def create!
      provider = result!(provider_create_service.call(attributes))
      result!(
        OAuthApplications::CreateService.new(wiki_provider: provider, user:).call(**oauth_application_attributes)
      )
      result!(
        OAuthClients::CreateService.new(user:).call(oauth_client_attributes.merge(integration: provider))
      )
    end

    def update!(provider)
      result! provider_update_service(provider).call(attributes)
      result!(
        OAuthApplications::UpdateService.new(wiki_provider: provider, user:).call(**oauth_application_attributes)
      )
      result!(
        OAuthClients::UpdateService.new(user:, model: provider.oauth_client).call(oauth_client_attributes)
      )
    end

    private

    def provider_create_service
      XWikiProviders::CreateService.new(
        user:,
        contract_class: XWikiProviders::EnvironmentCreateContract
      )
    end

    def provider_update_service(provider)
      XWikiProviders::UpdateService.new(
        user:,
        model: provider,
        contract_class: XWikiProviders::EnvironmentUpdateContract
      )
    end

    def attributes
      {
        name: config.fetch(:name),
        url: config.fetch(:url),
        universal_identifier: config[:uid]
      }.compact
    end

    def oauth_application_attributes
      {
        client_id: config_dig!(:openproject_oauth, :client_id),
        client_secret: config_dig!(:openproject_oauth, :client_secret)
      }
    end

    def oauth_client_attributes
      {
        client_id: config_dig!(:xwiki_oauth, :client_id),
        client_secret: config_dig!(:xwiki_oauth, :client_secret)
      }
    end
  end
end
