# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Reporting::CostReportsController do
  include OpenProject::Reporting::PluginSpecHelper

  let(:user) { create(:user) }
  let(:project) { create(:valid_project) }

  before do
    allow(User).to receive(:current).and_return(user)
  end

  describe "GET show" do
    before do
      is_member project, user, [:view_cost_entries]
    end

    it "returns 404 for a report that does not exist" do
      get :show, params: { id: 1, unit: -1 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE destroy" do
    let(:user) { create(:admin) }
    let!(:report) { create(:cost_report, principal: user, project:, public: true) }

    context "with valid params" do
      before do
        delete :destroy, params: { id: report.id, project_id: project.identifier }
      end

      it "destroys the report" do
        expect(CostReport.count).to be_zero
      end

      it "redirects" do
        expect(response).to have_http_status(:see_other)
      end
    end

    context "with an id that does not exist" do
      before do
        delete :destroy, params: { id: 0, project_id: project.identifier }
      end

      it "keeps the report" do
        expect(CostReport.count).to eq(1)
      end

      it "returns 404 Not found" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a user lacking the permission" do
      let(:user) { create(:user) }

      before do
        is_member project, user, [:view_cost_entries]

        delete :destroy, params: { id: report.id, project_id: project.identifier }
      end

      it "keeps the report" do
        expect(CostReport.count).to eq(1)
      end

      it "returns 403 Forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST rename" do
    let!(:report) { create(:cost_report, principal: user, project:, public: true) }

    context "when only save_private_cost_reports is granted" do
      before do
        is_member project, user, %i[view_cost_entries save_private_cost_reports]

        post :rename, params: { id: report.id, project_id: project.identifier, query_name: "Renamed" }
      end

      it "returns forbidden, because the report is public" do
        expect(response).to have_http_status(:forbidden)
      end

      it "does not rename the report" do
        expect(report.reload.name).not_to eq("Renamed")
      end
    end

    context "when save_cost_reports is granted" do
      before do
        is_member project, user, %i[view_cost_entries save_cost_reports]

        post :rename, params: { id: report.id, project_id: project.identifier, query_name: "Renamed" }
      end

      it "renames the report" do
        expect(report.reload.name).to eq("Renamed")
      end

      it "redirects to the report" do
        expect(response).to redirect_to(project_reporting_cost_report_path(project, report))
      end
    end
  end

  describe "POST save_as" do
    context "when only save_private_cost_reports is granted" do
      before do
        is_member project, user, %i[view_cost_entries save_private_cost_reports]
      end

      it "does not create a public report when one is requested" do
        post :create, params: { query_name: "Public attempt", query_is_public: "1" }

        expect(response).to have_http_status(:forbidden)
        expect(CostReport.count).to be_zero
      end

      it "still allows creating a private report" do
        post :create, params: { query_name: "Private" }

        expect(CostReport.last).not_to be_public
        expect(CostReport.last.name).to eq("Private")
      end
    end

    context "when save_cost_reports is granted" do
      before do
        is_member project, user, %i[view_cost_entries save_cost_reports]
      end

      it "creates a public report when one is requested" do
        post :create, params: { query_name: "Public", query_is_public: "1" }

        expect(CostReport.last).to be_public
      end
    end
  end
end
