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
require_module_spec_helper

RSpec.describe API::V3::Storages::StorageRepresenter, "parsing" do
  let(:current_user) { build_stubbed(:user) }
  let(:representer) { described_class.new(storage, current_user:) }

  subject(:parsed) { representer.from_hash parsed_hash }

  describe "OneDrive" do
    let(:storage) { build_stubbed(:onedrive_storage) }
    let(:parsed_hash) do
      {
        "name" => "My OneDrive",
        "tenantId" => "e36f1dbc-fdae-427e-b61b-0d96ddfb81a4",
        "_links" => {
          "type" => {
            "href" => API::V3::Storages::URN_STORAGE_TYPE_ONE_DRIVE
          }
        }
      }
    end

    context "with basic attributes" do
      it "is parsed correctly" do
        expect(parsed).to have_attributes(name: "My OneDrive",
                                          tenant_id: "e36f1dbc-fdae-427e-b61b-0d96ddfb81a4",
                                          provider_type: "Storages::OneDriveStorage")

        aggregate_failures "honors provider fields defaults" do
          expect(parsed).not_to be_automatic_management_enabled
          expect(parsed).to be_health_notifications_enabled
        end
      end
    end
  end

  describe "Nextcloud" do
    let(:storage) { build_stubbed(:nextcloud_storage) }
    let(:parsed_hash) do
      {
        "name" => "Nextcloud Local",
        "_links" => {
          "origin" => {
            "href" => storage.host
          },
          "type" => {
            "href" => API::V3::Storages::URN_STORAGE_TYPE_NEXTCLOUD
          }
        }
      }
    end

    context "with basic attributes" do
      it "is parsed correctly" do
        expect(parsed).to have_attributes(name: "Nextcloud Local",
                                          host: storage.host,
                                          provider_type: "Storages::NextcloudStorage")

        aggregate_failures "honors provider fields defaults" do
          expect(parsed).not_to be_automatically_managed
          expect(parsed).to be_health_notifications_enabled
        end
      end
    end

    context "with SSO authentication" do
      before do
        parsed_hash["_links"]["authenticationMethod"] = {
          "href" => "urn:openproject-org:api:v3:storages:authenticationMethod:OAuth2SSO"
        }
        parsed_hash["storageAudience"] = "the-new-storage-audience"
        parsed_hash["tokenExchangeScope"] = "one-scope two-scope"
      end

      it "parses the authentication method" do
        expect(parsed.authentication_method).to eq("oauth2_sso")
      end

      it "parses the storage audience" do
        expect(parsed.storage_audience).to eq("the-new-storage-audience")
      end

      it "parses the token exchange scope" do
        expect(parsed.token_exchange_scope).to eq("one-scope two-scope")
      end
    end

    describe "automatically managed project folders" do
      context "with applicationPassword" do
        let(:parsed_hash) do
          super().merge(
            "applicationPassword" => "secret"
          )
        end

        it "is parsed correctly" do
          expect(parsed).to have_attributes(automatically_managed: true, password: "secret")
        end
      end

      context "with applicationPassword null" do
        let(:parsed_hash) do
          super().merge(
            "applicationPassword" => nil
          )
        end

        it "is parsed as automatic folder management disabled" do
          expect(parsed).to have_attributes(automatically_managed: false, password: nil)
        end
      end

      context "with applicationPassword blank" do
        let(:parsed_hash) do
          super().merge(
            "applicationPassword" => ""
          )
        end

        it "is parsed as automatic folder management disabled" do
          expect(parsed).to have_attributes(automatically_managed: false, password: nil)
        end
      end
    end
  end
end
