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

RSpec.describe Storages::Admin::HealthStatusController do
  let(:user) { build_stubbed(:admin) }
  let(:storage) { create(:nextcloud_storage_configured) }
  let(:params) { { storage_id: storage.id } }

  before do
    visible_relation = instance_double(ActiveRecord::Relation)
    allow(Storages::Storage).to receive(:visible).and_return(visible_relation)
    allow(visible_relation).to receive(:find).with(storage.id.to_s).and_return(storage)

    login_as user
  end

  context "if not admin" do
    let(:user) { build_stubbed(:user) }

    it "renders 403" do
      get :show, params: params
      expect(response).to have_http_status :forbidden
    end
  end

  context "if not logged in" do
    let(:user) { User.anonymous }

    it "renders 403" do
      get :show, params: params
      expect(response.status)
        .to redirect_to signin_url(back_url: admin_settings_storage_health_status_report_url(storage))
    end
  end

  describe "#show" do
    it "renders the show page" do
      get :show, params: params
      expect(response).to be_successful
      expect(response).to render_template "show"
    end

    it "sends the text version of the report when requested" do
      # Creating an actual report result and caching it so we can test the rendering of the response
      validator = Storages::Adapters::Registry["nextcloud.validators.connection"].new(storage)
      report = validator.call
      report.save!

      get :show, params: params.merge(format: :txt)

      expect(response).to be_successful
      expect(response.headers["Content-Type"]).to eq "text/plain"
      expect(response.headers["Content-Disposition"]).to match(/attachment; filename=".+_health_report_.+.txt"/)

      yaml = YAML.load(response.body)
      expect(yaml["storage"]).to eq storage.name
      expect(yaml["storage_type"]).to eq storage.to_s
      expect(yaml.dig("results", 0, "results", 0, "state")).to eq(:success)
      expect(yaml.dig("configuration", "host")).to eq(storage.host)
    end
  end

  describe "#create" do
    before do
      validator = instance_double(Storages::Adapters::Providers::Nextcloud::Validators::ConnectionValidator)
      report = storage.health_reports.build
      allow(Storages::Adapters::Providers::Nextcloud::Validators::ConnectionValidator).to receive(:new).and_return(validator)
      allow(validator).to receive_messages(call: report)
    end

    it "creates a health report and redirects to show" do
      post :create, params: params
      expect(response.status).to redirect_to admin_settings_storage_health_status_report_path(storage)
      expect(storage.reload.health_reports.count).to eq(1)
    end
  end

  describe "#create_health_status_report" do
    before do
      validator = instance_double(Storages::Adapters::Providers::Nextcloud::Validators::ConnectionValidator)
      report = storage.health_reports.build
      allow(Storages::Adapters::Providers::Nextcloud::Validators::ConnectionValidator).to receive(:new).and_return(validator)
      allow(validator).to receive_messages(call: report)
    end

    it "creates and caches a health status report and updates page via turbo stream" do
      post :create_health_status_report, params: params, as: :turbo_stream
      expect(response).to be_successful
    end
  end
end
