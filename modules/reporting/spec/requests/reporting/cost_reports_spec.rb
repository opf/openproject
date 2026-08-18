# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe "Cost reports", :aggregate_failures, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[costs]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_cost_entries view_time_entries save_cost_reports] })
  end

  before { login_as(user) }

  describe "GET /reporting/cost_reports" do
    it "renders a report built from the default filters" do
      get global_reporting_cost_reports_path

      expect(response).to have_http_status(:ok)
    end

    it "renders each part of the form exactly once" do
      get global_reporting_cost_reports_path

      expect(response.body.scan("Add filter").size).to eq(1)
      expect(response.body.scan(%r{<div[^>]*id="group-by--columns"}).size).to eq(1)
      expect(response.body.scan('id="query_form"').size).to eq(1)
    end
  end

  describe "GET /projects/:project_id/reporting/cost_reports" do
    it "renders a report scoped to the project" do
      get project_reporting_cost_reports_path(project)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /reporting/cost_reports/:id" do
    let(:report) do
      CostReport.create!(name: "Saved", principal: user, public: true, query: CostReportQuery.new)
    end

    it "renders the saved report" do
      get reporting_cost_report_path(report)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Saved")
    end

    it "404s for a report that is not visible" do
      other = CostReport.create!(name: "Private", principal: create(:user), public: false,
                                 query: CostReportQuery.new)

      get reporting_cost_report_path(other)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /cost_reports/:id, the pre-migration url" do
    let(:report) do
      CostReport.create!(name: "Converted", principal: user, public: true, query: CostReportQuery.new,
                         legacy_cost_query_id: 4711)
    end

    it "redirects to the report that was converted from it" do
      report

      get "/cost_reports/4711"

      expect(response).to redirect_to(reporting_cost_report_path(report))
      expect(response).to have_http_status(:moved_permanently)
    end

    it "404s for an id that was never converted" do
      get "/cost_reports/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /cost_reports, the pre-migration index" do
    it "redirects to the new index" do
      get "/cost_reports"

      expect(response).to redirect_to(global_reporting_cost_reports_path)
    end
  end
end
