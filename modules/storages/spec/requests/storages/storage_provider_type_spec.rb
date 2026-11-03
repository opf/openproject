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

require "spec_helper"
require_module_spec_helper

RSpec.describe "Creating a storage with a provider type", :skip_csrf, :webmock, type: :rails_request do
  include API::V3::Utilities::PathHelper

  shared_let(:admin) { create(:admin) }

  current_user { admin }

  before do
    stub_const("ProviderTypeProbe", Class.new)
    allow(ProviderTypeProbe).to receive(:new)
  end

  describe "POST /api/v3/storages" do
    let(:links) { { origin: { href: "https://example.nextcloud.local/" } } }

    def create_storage
      post api_v3_paths.storages,
           params: { name: "APIStorage", _links: links }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
    end

    context "with a provider type that is not registered" do
      let(:links) { super().merge(type: { href: "ProviderTypeProbe" }) }

      it "rejects the request", :aggregate_failures do
        expect { create_storage }.not_to change(Storages::Storage, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(ProviderTypeProbe).not_to have_received(:new)
      end
    end

    context "without a provider type" do
      it "rejects the request", :aggregate_failures do
        expect { create_storage }.not_to change(Storages::Storage, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /admin/settings/storages" do
    let(:storage_params) { { name: "FormStorage", host: "https://example.nextcloud.local/" } }

    def create_storage
      post admin_settings_storages_path, params: { storages_storage: storage_params }
    end

    context "with a provider type that is not registered" do
      let(:storage_params) { super().merge(provider_type: "ProviderTypeProbe") }

      it "redirects to the storage list", :aggregate_failures do
        expect { create_storage }.not_to change(Storages::Storage, :count)

        expect(response).to redirect_to(admin_settings_storages_path)
        expect(flash[:error]).to eq(I18n.t("storages.error_invalid_provider_type"))
        expect(ProviderTypeProbe).not_to have_received(:new)
      end
    end

    context "without a provider type" do
      it "redirects to the storage list", :aggregate_failures do
        expect { create_storage }.not_to change(Storages::Storage, :count)

        expect(response).to redirect_to(admin_settings_storages_path)
        expect(flash[:error]).to eq(I18n.t("storages.error_invalid_provider_type"))
      end
    end
  end
end
