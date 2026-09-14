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

require "spec_helper"
require_module_spec_helper
require "httpx/plugins/oauth"

module Storages
  module Adapters
    module AuthenticationStrategies
      # httpx keeps refreshed tokens inside OAuthSession without public readers,
      # so #update_token digs them out via #send. Pinned here so that an httpx
      # upgrade that moves them fails this spec first.
      RSpec.describe OAuthUserToken, "httpx contract" do
        let(:session) do
          HTTPX.plugin(:oauth).with(
            oauth_options: {
              issuer: "https://example.com",
              client_id: "client-id",
              client_secret: "client-secret",
              access_token: "seeded-access-token",
              refresh_token: "seeded-refresh-token"
            }
          )
        end

        let(:oauth_session) { session.send(:oauth_session) }

        it "exposes the oauth session on the httpx session" do
          expect(oauth_session).to be_a(HTTPX::Plugins::OAuth::OAuthSession)
        end

        it "exposes the token pair read by #update_token" do
          expect(oauth_session.access_token).to eq("seeded-access-token")
          expect(oauth_session.send(:refresh_token)).to eq("seeded-refresh-token")
        end
      end
    end
  end
end
