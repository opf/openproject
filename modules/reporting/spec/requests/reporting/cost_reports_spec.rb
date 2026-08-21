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

  describe "the pre-migration filter syntax, as linked from a work package" do
    it "translates fields/operators/values into the compact syntax" do
      get "/cost_reports", params: { "fields[]": "WorkPackageId",
                                     "operators[WorkPackageId]": "=",
                                     "values[WorkPackageId]": "42",
                                     set_filter: 1 }

      expect(response).to redirect_to(
        global_reporting_cost_reports_path(filters: 'work_package_id = "42"')
      )
    end

    it "translates a custom field filter to its attribute" do
      get "/cost_reports", params: { "operators[CustomField7]": "=", "values[CustomField7]": "a", set_filter: 1 }

      expect(response).to redirect_to(
        global_reporting_cost_reports_path(filters: 'cf_7 = "a"')
      )
    end

    it "translates the group bys" do
      get "/cost_reports", params: { "operators[ProjectId]": "=",
                                     "values[ProjectId]": "1",
                                     groups: { rows: %w[WorkPackageId], columns: %w[Week] } }

      expect(response).to redirect_to(
        global_reporting_cost_reports_path(filters: 'project_id = "1"', rows: "work_package_id", columns: "week")
      )
    end

    it "keeps the selected unit" do
      get "/cost_reports", params: { "operators[ProjectId]": "=", "values[ProjectId]": "1", unit: "-1" }

      expect(response.location).to include("unit=-1")
    end

    it "redirects to the plain index when no filters are given" do
      get "/cost_reports"

      expect(response).to redirect_to(global_reporting_cost_reports_path)
    end

    it "carries the filters onto a converted report" do
      report = CostReport.create!(name: "Converted", principal: user, public: true, query: CostReportQuery.new,
                                  legacy_cost_query_id: 4711)

      get "/cost_reports/4711", params: { "operators[ProjectId]": "=", "values[ProjectId]": "1" }

      expect(response).to redirect_to(
        reporting_cost_report_path(report, filters: 'project_id = "1"')
      )
    end
  end

  describe "filters on the url" do
    it "applies them to the report" do
      get global_reporting_cost_reports_path,
          params: { filters: 'spent_on >d "2020-01-01" & user_id = "me"', rows: "project_id", columns: "week" }

      expect(response).to have_http_status(:ok)
    end

    it "treats an empty filters param as no filters rather than as the default" do
      get global_reporting_cost_reports_path, params: { filters: "" }

      expect(response).to have_http_status(:ok)
    end

    # An empty axis is left out of the url, so a request that configures anything
    # must not fall back to the default axes for the ones it omits.
    it "leaves both axes empty when the url only carries filters" do
      get global_reporting_cost_reports_path, params: { filters: 'user_id = "me"' }

      expect(response).to have_http_status(:ok)
      expect(response.body.scan("data-group-by=").size).to eq(0)
    end

    # Without a group by the flat entry table renders, which asks the controller
    # for the selected unit. This is what a link from a work package produces.
    # It needs an entry to report on, or the table short circuits to its empty
    # state and never gets there.
    it "renders the flat entry table when nothing is grouped" do
      work_package = create(:work_package, project:)
      create(:time_entry, work_package:, project:, user:, hours: 2)

      get project_reporting_cost_reports_path(project),
          params: { filters: %(work_package_id = "#{work_package.id}") }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("generic-table")
      expect(response.body).not_to include(I18n.t(:no_results_title_text))
    end
  end

  describe "a session left over from before filters lived on the url" do
    let(:legacy_session) do
      { filters: { operators: { spent_on: ">d", user_id: "=" },
                   values: { spent_on: ["2020-01-01"], user_id: ["me"] } },
        groups: { rows: [:project_id], columns: [:week] } }
    end

    it "redirects to the url carrying those filters and forgets the session" do
      # rails_request specs cannot seed the session, so the migration is driven
      # through the object the controller uses.
      filters = CostReports::SessionFilters.new({ CostReports::SessionFilters::KEY => legacy_session })

      expect(filters).to be_any

      params = filters.take!

      expect(params[:filters]).to eq('spent_on >d "2020-01-01" & user_id = "me"')
      expect(params[:rows]).to eq("project_id")
      expect(params[:columns]).to eq("week")
    end

    it "is not present once taken" do
      session = { CostReports::SessionFilters::KEY => legacy_session }
      filters = CostReports::SessionFilters.new(session)
      filters.take!

      expect(session).to be_empty
      expect(CostReports::SessionFilters.new(session)).not_to be_any
    end
  end
end
