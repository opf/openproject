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

RSpec.describe Storages::Admin::StoragesController do
  let(:user) { build(:admin) }

  before do
    login_as user
  end

  describe "GET #upsell" do
    it "renders the upsell page" do
      get :upsell
      expect(response).to be_successful
      expect(response).to render_template "upsell"
    end

    context "with one_drive provider" do
      it "assigns the correct provider type" do
        get :upsell, params: { provider: "one_drive" }
        expect(assigns(:provider_type).short_provider_name).to eq(:one_drive)
      end
    end

    context "with sharepoint provider" do
      it "assigns the correct provider type" do
        get :upsell, params: { provider: "sharepoint" }
        expect(assigns(:provider_type).short_provider_name).to eq(:sharepoint)
      end
    end

    context "with missing provider param" do
      it "defaults to one_drive provider type" do
        get :upsell
        expect(assigns(:provider_type).short_provider_name).to eq(:one_drive)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:storage) { build_stubbed(:nextcloud_storage) }
    let(:service_result) { ServiceResult.success }
    let(:delete_service) { instance_double(Storages::Storages::DeleteService, call: service_result) }

    before do
      allow(Storages::Storage).to receive(:visible).and_return(instance_double(ActiveRecord::Relation, find: storage))
      allow(Storages::Storages::DeleteService).to receive(:new).and_return(delete_service)
    end

    it "redirects to storages index with see_other" do
      delete :destroy, params: { id: storage.id }
      expect(response).to redirect_to(admin_settings_storages_path)
      expect(response).to have_http_status(:see_other)
    end
  end
end
