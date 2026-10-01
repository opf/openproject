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
  module OAuthApplications
    class CreateService
      OIDC_CALLBACK_PATH = "oidc/authenticator/callback"

      attr_accessor :user, :wiki_provider

      def initialize(wiki_provider:, user:)
        @wiki_provider = wiki_provider
        @user = user
      end

      def call(client_id: nil, client_secret: nil)
        result = nil
        ApplicationRecord.transaction do
          wiki_provider.oauth_application&.destroy!
          result = ::OAuth::Applications::CreateService.new(user:).call(
            **attributes(client_id:, client_secret:)
          )
          raise ActiveRecord::Rollback unless result.success?
        end
        result
      end

      private

      def attributes(client_id:, client_secret:)
        {
          name: wiki_provider.name,
          redirect_uri:,
          scopes: "api_v3",
          confidential: true,
          owner: user,
          integration: wiki_provider,
          uid: client_id,
          secret: client_secret
        }.compact
      end

      def redirect_uri
        URI.join("#{wiki_provider.url.chomp('/')}/", OIDC_CALLBACK_PATH).to_s
      end
    end
  end
end
