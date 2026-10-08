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

require "spec_helper"

RSpec.describe OpenProject::Authentication::Strategies::Warden::DoorkeeperOAuth do
  subject(:strategy) { described_class.new(env, warden_scope) }

  let(:user) { create(:user) }
  let(:warden_scope) { :api_v3 }
  let(:token_scopes) { "api_v3" }
  let(:access_token) { create(:oauth_access_token, resource_owner: user, scopes: token_scopes) }
  let(:env) do
    Rack::MockRequest.env_for("/api/v3/projects", "HTTP_AUTHORIZATION" => "Bearer #{access_token.plaintext_token}")
  end

  before do
    allow(OpenProject::Authentication).to receive(:restricted_oauth_scopes).and_call_original
    allow(OpenProject::Authentication)
      .to receive(:restricted_oauth_scopes)
      .with(:api_v3)
      .and_return(["restricted_scope"])
  end

  shared_examples "authenticates the user" do
    it "succeeds and exposes the access token in the env" do
      strategy.authenticate!

      expect(strategy.result).to eq(:success)
      expect(strategy.user).to eq(user)
      expect(env[described_class::ACCESS_TOKEN_ENV_KEY]).to eq(access_token)
    end
  end

  shared_examples "fails with insufficient scope" do
    it "fails without exposing the access token" do
      strategy.authenticate!

      expect(strategy.result).to eq(:failure)
      expect(strategy.message).to eq("insufficient_scope")
      expect(env).not_to have_key(described_class::ACCESS_TOKEN_ENV_KEY)
    end
  end

  context "with a token granting the Warden scope" do
    it_behaves_like "authenticates the user"
  end

  context "with a token granting a restricted scope registered for the Warden scope" do
    let(:token_scopes) { "restricted_scope" }

    it_behaves_like "authenticates the user"
  end

  context "with a token granting a restricted scope registered for another Warden scope" do
    let(:warden_scope) { :mcp }
    let(:token_scopes) { "restricted_scope" }

    it_behaves_like "fails with insufficient scope"
  end

  context "with a token granting an unknown scope" do
    let(:token_scopes) { "unknown_scope" }

    it_behaves_like "fails with insufficient scope"
  end
end
