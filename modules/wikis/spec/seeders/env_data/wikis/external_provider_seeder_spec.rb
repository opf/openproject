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

RSpec.describe EnvData::Wikis::ExternalProviderSeeder do
  subject { described_class.new(seed_data).seed! }

  let(:seed_data) { Source::SeedData.new({}) }

  it "does not seed any providers" do
    expect { subject }.not_to change(Wikis::Provider, :count)
  end

  context "when configuring an XWiki provider", with_settings: {
    wiki_providers: [
      {
        type: "xwiki",
        name: "My custom XWiki",
        url: "https://xwiki.example.com",
        openproject_oauth: { client_id: "xwiki-123", client_secret: "Password123" },
        xwiki_oauth: { client_id: "openproject-123", client_secret: "Password456" }
      }.deep_stringify_keys
    ]
  } do
    it "seeds the provider with expected data" do
      expect { subject }.to change(Wikis::Provider, :count).from(0).to(1)

      expect(Wikis::XWikiProvider.first.name).to eq("My custom XWiki")
      expect(Wikis::XWikiProvider.first.url).to eq("https://xwiki.example.com")
      expect(Wikis::XWikiProvider.first.oauth_application.uid).to eq("xwiki-123")
      expect(Wikis::XWikiProvider.first.oauth_client.client_id).to eq("openproject-123")
    end

    it "enqueues a job to update the universal identifier" do
      expect { subject }.to have_enqueued_job(Wikis::XWikiProviders::FetchInstanceIdJob)
    end

    context "and when a provider with the same name exists" do
      let(:existing_provider) { create(:xwiki_provider, :with_oauth_configured, name: "My custom XWiki") }

      before do
        existing_provider
      end

      it "does not seed the provider twice" do
        expect { subject }.not_to change(Wikis::Provider, :count)
      end
    end
  end

  context "when configuring an XWiki provider with a uid", with_settings: {
    wiki_providers: [
      {
        type: "xwiki",
        name: "My custom XWiki",
        url: "https://xwiki.example.com",
        uid: "abc-123",
        openproject_oauth: { client_id: "xwiki-123", client_secret: "Password123" },
        xwiki_oauth: { client_id: "openproject-123", client_secret: "Password456" }
      }.deep_stringify_keys
    ]
  } do
    it "seeds the provider with expected data" do
      expect { subject }.to change(Wikis::Provider, :count).from(0).to(1)

      expect(Wikis::XWikiProvider.first.name).to eq("My custom XWiki")
      expect(Wikis::XWikiProvider.first.url).to eq("https://xwiki.example.com")
      expect(Wikis::XWikiProvider.first.universal_identifier).to eq("abc-123")
      expect(Wikis::XWikiProvider.first.oauth_application.uid).to eq("xwiki-123")
      expect(Wikis::XWikiProvider.first.oauth_client.client_id).to eq("openproject-123")
    end

    it "enqueues no job to update the universal identifier" do
      expect { subject }.not_to have_enqueued_job(Wikis::XWikiProviders::FetchInstanceIdJob)
    end

    context "and when a provider with the same uid exists" do
      let(:existing_provider) do
        create(:xwiki_provider, :with_oauth_configured, universal_identifier: "abc-123", name: "Old name")
      end

      before do
        existing_provider
      end

      it "does not seed the provider twice" do
        expect { subject }.not_to change(Wikis::Provider, :count)
      end

      it "renames the provider" do
        expect { subject }.to change { Wikis::XWikiProvider.first.name }.from("Old name").to("My custom XWiki")
      end
    end
  end

  context "when not specifying a type", with_settings: {
    wiki_providers: [
      {
        name: "My custom XWiki",
        url: "https://xwiki.example.com",
        openproject_oauth: { client_id: "xwiki-123", client_secret: "Password123" },
        xwiki_oauth: { client_id: "openproject-123", client_secret: "Password456" }
      }.deep_stringify_keys
    ]
  } do
    it "raises an error" do
      expect { subject }.to raise_error(KeyError)
    end
  end

  context "when specifying an unknown type", with_settings: {
    wiki_providers: [
      {
        type: "ywiki",
        name: "My custom XWiki",
        url: "https://xwiki.example.com",
        openproject_oauth: { client_id: "xwiki-123", client_secret: "Password123" },
        xwiki_oauth: { client_id: "openproject-123", client_secret: "Password456" }
      }.deep_stringify_keys
    ]
  } do
    it "raises an error" do
      expect { subject }.to raise_error(/Unsupported external wiki provider/)
    end
  end
end
