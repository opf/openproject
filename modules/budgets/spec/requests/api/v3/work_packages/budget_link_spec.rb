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
require "rack/test"

RSpec.describe "API v3 work package budget link" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project, enabled_module_names: %w[work_package_tracking budgets]) }
  let(:budget) { create(:budget, project:, subject: "Q4 Acquisition Client X") }
  let(:work_package) { create(:work_package, project:, budget:) }
  let(:permissions) { [:view_work_packages] }
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  subject(:response) { last_response }

  describe "GET /api/v3/work_packages/:id" do
    before do
      login_as(current_user)
      get api_v3_paths.work_package(work_package.id)
    end

    it "returns the work package" do
      expect(response).to have_http_status(:ok)
    end

    context "when the user may view work packages but not budgets" do
      it "renders an undisclosed budget link" do
        expect(response.body)
          .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
                .at_path("_links/budget/href")

        expect(response.body)
          .to be_json_eql(I18n.t(:"api_v3.undisclosed.budget").to_json)
                .at_path("_links/budget/title")
      end

      it "does not include the budget subject or resource path" do
        expect(response.body).not_to include(budget.subject)
        expect(response.body).not_to include(api_v3_paths.budget(budget.id))
      end

      it "does not embed the budget" do
        expect(response.body).not_to have_json_path("_embedded/budget")
      end

      context "when no budget is assigned" do
        let(:work_package) { create(:work_package, project:) }

        it "renders an empty budget link" do
          expect(response.body)
            .to be_json_eql(nil.to_json)
                  .at_path("_links/budget/href")

          expect(response.body).not_to have_json_path("_links/budget/title")
        end
      end
    end

    context "when the user may view budgets" do
      let(:permissions) { %i[view_work_packages view_budgets] }

      it "includes the budget subject and resource path" do
        expect(response.body)
          .to be_json_eql(api_v3_paths.budget(budget.id).to_json)
                .at_path("_links/budget/href")

        expect(response.body)
          .to be_json_eql(budget.subject.to_json)
                .at_path("_links/budget/title")
      end
    end
  end

  describe "POST /api/v3/work_packages/:id/form" do
    let(:permissions) { %i[view_work_packages edit_work_packages] }

    before do
      login_as(current_user)
      post api_v3_paths.work_package_form(work_package.id),
           { lockVersion: work_package.lock_version }.to_json,
           "CONTENT_TYPE" => "application/json"
    end

    it "returns the form" do
      expect(response).to have_http_status(:ok)
    end

    it "renders an undisclosed budget link in the payload" do
      expect(response.body)
        .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
              .at_path("_embedded/payload/_links/budget/href")

      expect(response.body)
        .to be_json_eql(I18n.t(:"api_v3.undisclosed.budget").to_json)
              .at_path("_embedded/payload/_links/budget/title")

      expect(response.body).not_to include(budget.subject)
      expect(response.body).not_to include(api_v3_paths.budget(budget.id))
    end

    context "when the user may view budgets" do
      let(:permissions) { %i[view_work_packages edit_work_packages view_budgets] }

      it "includes the budget subject and resource path in the payload link" do
        expect(response.body)
          .to be_json_eql(api_v3_paths.budget(budget.id).to_json)
                .at_path("_embedded/payload/_links/budget/href")

        expect(response.body)
          .to be_json_eql(budget.subject.to_json)
                .at_path("_embedded/payload/_links/budget/title")
      end
    end
  end

  describe "PATCH /api/v3/work_packages/:id" do
    let(:permissions) { %i[view_work_packages edit_work_packages] }

    before do
      login_as(current_user)
      patch api_v3_paths.work_package(work_package.id),
            {
              lockVersion: work_package.lock_version,
              _links: { budget: { href: API::V3::URN_UNDISCLOSED } }
            }.to_json,
            "CONTENT_TYPE" => "application/json"
    end

    it "keeps the assigned budget and does not disclose it" do
      expect(response).to have_http_status(:ok)
      expect(work_package.reload.budget_id).to eq(budget.id)

      expect(response.body)
        .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
              .at_path("_links/budget/href")

      expect(response.body).not_to include(budget.subject)
    end
  end
end
