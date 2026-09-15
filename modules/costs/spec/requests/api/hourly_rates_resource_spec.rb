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
require "rack/test"

RSpec.describe "API v3 hourly rates", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_hourly_rates edit_hourly_rates] })
  end

  shared_let(:project_rate) do
    create(:hourly_rate, principal: user, project:, valid_from: Date.new(2025, 1, 1), rate: 50)
  end
  shared_let(:default_rate) do
    create(:default_hourly_rate, principal: user, valid_from: Date.new(2025, 1, 1), rate: 30)
  end

  let(:collection_path) { api_v3_paths.hourly_rates_by_principal(user.id) }

  current_user { user }

  describe "GET the collection" do
    before { get collection_path }

    it "returns both rates" do
      expect(last_response).to have_http_status(:ok)
      expect(JSON.parse(last_response.body)["total"]).to eq(2)
    end

    it "tells project and default rates apart by the project link" do
      elements = JSON.parse(last_response.body).dig("_embedded", "elements")
      by_rate = elements.index_by { |element| element["rate"] }

      expect(by_rate[50.0]["_links"]["project"]["href"]).to eq(api_v3_paths.project(project.id))
      expect(by_rate[30.0]["_links"]).not_to have_key("project")
    end

    it "links the principal, resolved to its concrete type" do
      element = JSON.parse(last_response.body).dig("_embedded", "elements").first

      expect(element["_links"]["principal"]["href"]).to eq(api_v3_paths.user(user.id))
      expect(element["_links"]).not_to have_key("user")
    end
  end

  describe "for a placeholder user" do
    shared_let(:placeholder) { create(:placeholder_user) }
    shared_let(:placeholder_membership) do
      create(:member, principal: placeholder, project:, roles: [create(:project_role)])
    end
    shared_let(:placeholder_rate) do
      create(:hourly_rate, principal: placeholder, project:, valid_from: Date.new(2025, 1, 1), rate: 80)
    end

    it "serves the rates under the principal" do
      get api_v3_paths.hourly_rates_by_principal(placeholder.id)

      expect(last_response).to have_http_status(:ok)

      element = JSON.parse(last_response.body).dig("_embedded", "elements").first
      expect(element["rate"]).to eq(80.0)
      expect(element["_links"]["principal"]["href"]).to eq(api_v3_paths.placeholder_user(placeholder.id))
    end

    it "creates a rate for it" do
      expect do
        post api_v3_paths.hourly_rates_by_principal(placeholder.id),
             { validFrom: "2026-01-01", rate: 95,
               _links: { project: { href: api_v3_paths.project(project.id) } } }.to_json
      end.to change { placeholder.rates.count }.by(1)

      expect(last_response).to have_http_status(:created)
    end
  end

  describe "GET a single rate" do
    it "renders it" do
      get api_v3_paths.hourly_rate(user.id, project_rate.id)

      expect(last_response).to have_http_status(:ok)
      expect(JSON.parse(last_response.body)["_type"]).to eq("HourlyRate")
    end
  end

  describe "POST" do
    let(:body) { { validFrom: "2026-01-01", rate: 95 }.merge(links).to_json }
    let(:links) { {} }

    context "with a project link" do
      let(:links) { { _links: { project: { href: api_v3_paths.project(project.id) } } } }

      it "creates a project rate" do
        expect { post collection_path, body }.to change(HourlyRate, :count).by(1)

        expect(last_response).to have_http_status(:created)
        expect(HourlyRate.order(:id).last.project_id).to eq(project.id)
      end
    end

    context "without a project link" do
      it "is refused, since default rates are admin only" do
        expect { post collection_path, body }.not_to change(DefaultHourlyRate, :count)
      end

      context "as an admin" do
        current_user { create(:admin) }

        it "creates a default rate" do
          expect { post collection_path, body }.to change(DefaultHourlyRate, :count).by(1)

          expect(last_response).to have_http_status(:created)
        end
      end
    end
  end

  describe "PATCH" do
    it "updates the rate" do
      patch api_v3_paths.hourly_rate(user.id, project_rate.id), { rate: 120 }.to_json

      expect(last_response).to have_http_status(:ok)
      expect(project_rate.reload.rate).to eq(120)
    end

    it "refuses moving the rate to a project the user cannot manage" do
      other_project = create(:project)

      patch api_v3_paths.hourly_rate(user.id, project_rate.id),
            { _links: { project: { href: api_v3_paths.project(other_project.id) } } }.to_json

      expect(last_response).to have_http_status(:forbidden)
      expect(project_rate.reload.project_id).to eq(project.id)
    end

    # project_id is writable on the create contract only, so even somebody who
    # may manage rates in both projects cannot move one between them.
    it "refuses moving the rate to a project the user can manage" do
      other_project = create(:project, members: { user => create(:project_role, permissions: %i[edit_hourly_rates]) })

      patch api_v3_paths.hourly_rate(user.id, project_rate.id),
            { _links: { project: { href: api_v3_paths.project(other_project.id) } } }.to_json

      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(project_rate.reload.project_id).to eq(project.id)
    end
  end

  describe "DELETE" do
    it "deletes the rate" do
      expect { delete api_v3_paths.hourly_rate(user.id, project_rate.id) }
        .to change(HourlyRate, :count).by(-1)
    end
  end

  describe "for a user whose rates are not visible" do
    current_user { create(:user) }

    it "is not found" do
      get collection_path

      expect(last_response).to have_http_status(:not_found)
    end
  end
end
