require "spec_helper"

RSpec.describe "Cost report showing my own times", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:project) { create(:project) }
  let(:user) { create(:admin) }
  let(:user2) { create(:admin) }

  let(:work_package) { create(:work_package, project:) }
  let!(:hourly_rate1) { create(:default_hourly_rate, user:, rate: 1.00, valid_from: 1.year.ago) }

  let!(:time_entry1) do
    create(:time_entry,
           user:,
           entity: work_package,
           project:,
           hours: 10)
  end
  let!(:time_entry2) do
    create(:time_entry,
           user: user2,
           entity: work_package,
           project:,
           hours: 15)
  end

  before do
    # Login as first user
    login_as user

    # Create and save cost report
    visit project_reporting_cost_reports_path(project)
  end

  shared_examples "me filter value" do |filter_name, filter_selector|
    it 'keeps the special "me" value for the current user' do
      user_autocompleter = find("opce-user-autocompleter##{filter_selector}")

      ng_select_clear(user_autocompleter, raise_on_missing: false)
      select_autocomplete(user_autocompleter, query: "me", results_selector: "body")

      click_on "Save"
      fill_in "query_name", with: "Query ME value"
      check "query_is_public"
      find_by_id("query-icon-save-button").click
      # wait until the save is complete
      expect(page).to have_css(".PageHeader-title", text: "Query ME value")

      expect(page).to have_css(".report", text: "10.00")

      report = nil
      retry_block do
        report = CostReport.last
        raise "Expected CostReport to exist" unless report
      end

      user_filter = report.query.filters.detect { |filter| filter.name.to_s == filter_name }
      expect(user_filter.values).to eq %w(me)

      # Login as the next user
      login_as user2

      # Create and save cost report
      visit project_reporting_cost_report_path(project, report)
      expect(page).to have_css(".report", text: "15.00")

      # Refresh the user_autocompleter value to avoid cuprite issues in case the internal nodeID changes (stale element)
      user_autocompleter = find("opce-user-autocompleter##{filter_selector}")
      expect_current_autocompleter_value(user_autocompleter, "me")
    end
  end

  describe "assignee filter" do
    let(:work_package) { create(:work_package, project:, assigned_to: user) }
    let(:work_package2) { create(:work_package, project:, assigned_to: user2) }

    let!(:time_entry1) do
      create(:time_entry,
             user:,
             entity: work_package,
             project:,
             hours: 10)
    end
    let!(:time_entry2) do
      create(:time_entry,
             user: user2,
             entity: work_package2,
             project:,
             hours: 15)
    end

    before do
      # Remove default user filter, add assignee filter
      find("#rm_box_user_id .filter_rem").click
      select "Assignee", from: "add_filter_select"
    end

    it_behaves_like "me filter value", "assigned_to_id", "assigned_to_id_select_1"
  end

  describe "user filter" do
    it_behaves_like "me filter value", "user_id", "user_id_select_1"
  end
end
