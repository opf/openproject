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

RSpec.describe Wikis::Adapters::Providers::XWiki::OAuthConfiguration do
  let(:wiki_provider) { build_stubbed(:xwiki_provider, url: "https://xwiki.example.com/xwiki") }
  let(:oauth_client) do
    build_stubbed(:oauth_client, client_id: "xwiki-uuid", client_secret: "xwiki-secret", integration: wiki_provider)
  end

  before do
    allow(wiki_provider).to receive(:oauth_client).and_return(oauth_client)
  end

  subject(:config) { described_class.new(wiki_provider) }

  describe ".new" do
    context "when oauth_client is missing" do
      before { allow(wiki_provider).to receive(:oauth_client).and_return(nil) }

      it "raises ArgumentError" do
        expect { config }.to raise_error(ArgumentError, /OAuth client/)
      end
    end
  end

  describe "#oauth_client" do
    it "exposes the provider oauth_client" do
      expect(config.oauth_client).to eq(oauth_client)
    end
  end

  describe "#scope" do
    it "requests the openid scope" do
      expect(config.scope).to eq(%w[openid])
    end
  end

  describe "#refresh_token_supported?" do
    it "returns false — XWiki does not issue refresh tokens" do
      expect(config.refresh_token_supported?).to be(false)
    end
  end

  describe "#authorization_uri" do
    it "points to XWiki's OIDC authorization endpoint" do
      uri = URI.parse(config.authorization_uri(state: "nonce"))
      expect(uri.host).to eq("xwiki.example.com")
      expect(uri.path).to eq("/xwiki/oidc/authorization")
    end

    it "includes the openid scope" do
      expect(config.authorization_uri).to include("scope=openid")
    end

    it "includes the state parameter when provided" do
      expect(config.authorization_uri(state: "abc123")).to include("state=abc123")
    end
  end

  describe "#basic_rack_oauth_client" do
    subject(:rack_client) { config.basic_rack_oauth_client }

    it "configures the rack client with correct attributes" do
      expect(rack_client).to have_attributes(
        identifier: "xwiki-uuid",
        secret: "xwiki-secret",
        token_endpoint: "/xwiki/oidc/token",
        authorization_endpoint: "/xwiki/oidc/authorization"
      )
    end

    context "when the provider URL has a trailing slash" do
      let(:wiki_provider) { build_stubbed(:xwiki_provider, url: "https://xwiki.example.com/xwiki/") }

      it "does not produce double slashes in endpoint paths" do
        expect(rack_client.token_endpoint).to eq("/xwiki/oidc/token")
        expect(rack_client.authorization_endpoint).to eq("/xwiki/oidc/authorization")
      end
    end

    context "when the provider URL has no subpath" do
      let(:wiki_provider) { build_stubbed(:xwiki_provider, url: "https://xwiki.example.com") }

      it "builds correct root-relative endpoint paths" do
        expect(rack_client.token_endpoint).to eq("/oidc/token")
        expect(rack_client.authorization_endpoint).to eq("/oidc/authorization")
      end
    end
  end
end
