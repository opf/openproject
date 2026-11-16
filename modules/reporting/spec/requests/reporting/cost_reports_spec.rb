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

    context "with a public report of a project the user cannot view" do
      let(:other_report) do
        CostReport.create!(name: "Elsewhere", principal: create(:user), public: true, query: CostReportQuery.new,
                           project: create(:project, enabled_module_names: %i[costs]))
      end

      it "404s on the global url" do
        get reporting_cost_report_path(other_report)

        expect(response).to have_http_status(:not_found)
        expect(response.body).not_to include("Elsewhere")
      end

      it "404s on the url of the user's own project" do
        get project_reporting_cost_report_path(project, other_report)

        expect(response).to have_http_status(:not_found)
        expect(response.body).not_to include("Elsewhere")
      end
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

    it "404s for a public report of a project the user cannot view" do
      CostReport.create!(name: "Elsewhere", principal: create(:user), public: true, query: CostReportQuery.new,
                         project: create(:project, enabled_module_names: %i[costs]), legacy_cost_query_id: 4712)

      get "/cost_reports/4712"

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
      create(:time_entry, entity: work_package, project:, user:, hours: 2)

      get project_reporting_cost_reports_path(project),
          params: { filters: %(work_package_id = "#{work_package.id}") }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("generic-table")
      expect(response.body).not_to include(I18n.t(:no_results_title_text))
    end
  end

  describe "saving a report with a custom field", :skip_csrf do
    shared_let(:custom_field) { create(:string_wp_custom_field) }

    let(:cf_attribute) { custom_field.column_name }
    let(:report) do
      CostReport.create!(name: "Saved", principal: user, public: false, query: CostReportQuery.new)
    end

    it "saves the custom field group by the report page offers" do
      get reporting_cost_report_path(report)
      offered = response.parsed_body.at_css(%(#group-by--add-columns option[data-label="#{custom_field.name}"]))["value"]

      post reporting_cost_report_path(report),
           params: { query_name: report.name,
                     save_query: 1,
                     filters: 'spent_on <>d ["2026-10-01","2026-10-31"] & user_id = "me"',
                     columns: "work_package_id,#{offered},activity_id",
                     rows: "spent_on",
                     unit: -1 }

      expect(response).to redirect_to(reporting_cost_report_path(report))
      expect(report.reload.pivot_columns).to eq(["work_package_id", cf_attribute, "activity_id"])
    end

    it "updates a report grouped and filtered by it" do
      post reporting_cost_report_path(report),
           params: { filters: %(#{cf_attribute} = "a"), columns: cf_attribute, rows: "spent_on", save_query: 1 }

      expect(response).to redirect_to(reporting_cost_report_path(report))
      report.reload
      expect(report.pivot_columns).to eq([cf_attribute])
      expect(report.query.filters.map(&:name)).to eq([cf_attribute.to_sym])
    end

    it "creates a report grouped by it" do
      expect do
        post save_as_reporting_cost_reports_path, params: { query_name: "New", rows: cf_attribute }
      end.to change(CostReport, :count).by(1)

      expect(CostReport.last.pivot_rows).to eq([cf_attribute])
    end

    it "translates the custom_field<id> names of urls created before" do
      post reporting_cost_report_path(report),
           params: { filters: %(custom_field#{custom_field.id} = "a"), columns: "custom_field#{custom_field.id}" }

      report.reload
      expect(report.pivot_columns).to eq([cf_attribute])
      expect(report.query.filters.map(&:name)).to eq([cf_attribute.to_sym])
    end

    it "groups the rendered report by it" do
      post reporting_cost_report_path(report), params: { columns: cf_attribute }

      expect(report.reload.group_bys.map { |group_by| group_by.class.underscore_name }).to include(cf_attribute)
    end
  end

  describe "the export links" do
    shared_let(:export_project) { create(:project, enabled_module_names: %i[costs work_package_tracking]) }
    shared_let(:exporting_user) do
      create(:user, member_with_permissions: {
               export_project => %i[view_cost_entries view_time_entries export_work_packages]
             })
    end

    before { login_as(exporting_user) }

    def export_href(format)
      response.parsed_body.at_css("a[data-controller='costs--export'][href*='.#{format}']")["href"]
    end

    def export_params(format)
      Rack::Utils.parse_query(URI(export_href(format)).query)
    end

    it "carries the filters and unit of the requested report" do
      get project_reporting_cost_reports_path(export_project,
                                              filters: 'work_package_id =_child_work_packages "42"', unit: "-1")

      %w[xls pdf].each do |format|
        expect(export_params(format)).to include("filters" => 'work_package_id =_child_work_packages "42"',
                                                 "unit" => "-1")
      end
    end

    it "leaves an unsaved report's timesheet to its default title" do
      expect do
        get project_reporting_cost_reports_path(export_project, format: :pdf, filters: ""),
            headers: { "Accept" => "application/json" }
      end.to have_enqueued_job(CostReports::PDF::ExportTimesheetJob)
        .with(hash_including(options: hash_including(report_name: nil)))
    end

    context "with a saved report" do
      let(:report) do
        query = CostReportQuery.new.tap { it.where("work_package_id", "=", ["42"]) }
        CostReport.create!(name: "Saved", principal: exporting_user, public: true, project: export_project, query:)
      end

      it "exports the report itself with its filters" do
        get project_reporting_cost_report_path(export_project, report)

        expect(URI(export_href("xls")).path).to eq(project_reporting_cost_report_path(export_project, report, format: :xls))
        expect(export_params("xls")["filters"]).to eq('work_package_id = "42"')
      end

      it "names the exported timesheet after the report" do
        expect do
          get project_reporting_cost_report_path(export_project, report, format: :pdf, filters: 'user_id = "me"'),
              headers: { "Accept" => "application/json" }
        end.to have_enqueued_job(CostReports::PDF::ExportTimesheetJob)
          .with(hash_including(query: hash_including(filters: 'user_id = "me"'),
                               options: hash_including(report_name: "Saved")))
      end

      it "replaces the page header with export links carrying the applied filters" do
        get project_reporting_cost_report_path(export_project, report, filters: 'user_id = "me"'),
            headers: { "Turbo-Frame" => "result-table" }

        stream = response.parsed_body.at_css(
          "turbo-stream[target='#{CostReports::IndexPageHeaderComponent.wrapper_key}']"
        )

        expect(stream.inner_html)
          .to include("#{project_reporting_cost_report_path(export_project, report, format: :xls)}?filters=user_id+%3D")
      end
    end

    it "keeps an empty filter set instead of falling back to the defaults" do
      get project_reporting_cost_reports_path(export_project, filters: "")

      expect(export_params("xls")).to include("filters" => "")
    end

    context "when applying filters, which only reloads the result table frame" do
      let(:header_stream_selector) do
        "turbo-stream[action='update'][target='#{CostReports::IndexPageHeaderComponent.wrapper_key}']"
      end

      it "replaces the page header so the export links carry the applied filters" do
        get project_reporting_cost_reports_path(export_project, filters: 'user_id = "me"'),
            headers: { "Turbo-Frame" => "result-table" }

        stream = response.parsed_body.at_css(header_stream_selector)

        expect(stream).to be_present
        expect(stream.inner_html).to include("cost_reports.xls?filters=user_id+%3D+%22me%22")
      end

      it "leaves the header alone on a full page load" do
        get project_reporting_cost_reports_path(export_project, filters: 'user_id = "me"')

        expect(response.parsed_body.at_css(header_stream_selector)).to be_nil
      end
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
