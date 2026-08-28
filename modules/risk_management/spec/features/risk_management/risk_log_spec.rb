# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Risk log" do
  current_user { create(:admin) }

  let(:risk_type) { create(:type, name: "Risk", builtin_identifier: "risk") }
  let!(:category) { RiskManagement::RiskCategory.create!(name: "Strategic") }
  let!(:default_status) { create(:status, name: "New", is_default: true, is_closed: false, position: 1) }
  let!(:evaluated_status) { create(:status, name: "Evaluated", is_default: false, is_closed: false, position: 2) }
  let!(:planned_status) { create(:status, name: "Mitigation planned", is_default: false, is_closed: false, position: 3) }
  let!(:mitigation_done_status) { create(:status, name: "Mitigation done", is_default: false, is_closed: false, position: 4) }
  let!(:occurred_status) { create(:status, name: "Occurred", is_default: false, is_closed: true, position: 5) }
  let!(:rejected_status) { create(:status, name: "Rejected", is_default: false, is_closed: true, position: 6) }
  let(:project) do
    create(:project, no_types: true).tap do |project|
      project.project_types.find_or_create_by!(type: risk_type) do |project_type|
        project_type.variant = risk_type.default_variant
      end
    end
  end
  let!(:risk) do
    create(
      :work_package,
      project:,
      type: risk_type,
      status: evaluated_status,
      subject: "Supplier outage",
      risk_owner: current_user,
      risk_likelihood: 95,
      risk_impact: 600_000,
      risk_category_ids: [category.id],
      risk_response: "mitigate"
    )
  end
  let!(:low_risk) do
    create(
      :work_package,
      project:,
      type: risk_type,
      status: occurred_status,
      subject: "Minor documentation issue",
      risk_likelihood: 10,
      risk_impact: 5_000,
      risk_category_ids: [category.id]
    )
  end

  before do
    RiskManagement::Configuration.new(
      impact_very_low_max: 10_000,
      impact_low_max: 50_000,
      impact_medium_max: 100_000,
      impact_high_max: 500_000
    ).save
    project.enabled_module_names |= %w[risk_log meetings]
  end

  it "shows the matrix, quick filters, risk list and create action" do
    visit project_risk_log_path(project)

    expect(page).to have_heading("Risk log")
    expect(page).to have_css(".op-risk-matrix__cell", count: 25)
    expect(page).to have_css(".op-risk-matrix__impact-axis", text: "Impact")
    expect(page).to have_css(".op-risk-matrix__likelihood-axis", text: "Likelihood")
    expect(page).to have_css(".op-risk-matrix__column-label", text: "High", exact_text: true)
    expect(page).to have_css(".op-risk-matrix__row-label", text: "High", exact_text: true)
    expect(page).to have_heading("Risk exposure distribution")
    expect(page).to have_heading("Risk mitigation status")
    expect(page).to have_link("Risk management plan")
    expect(page).to have_css(".op-risk-log-dashboard--primary.widget-boxes")
    expect(page).to have_css(".op-risk-log-dashboard--secondary.widget-boxes")
    expect(page).to have_css(".op-risk-matrix.widget-box")
    expect(page).to have_css(".op-risk-metrics.widget-boxes")
    expect(page).to have_css(".op-risk-metrics__link", count: 4)
    expect(page).to have_css(".op-risk-metrics__link[aria-label]", count: 4)
    expect(page).to have_heading("Top risk exposure")
    expect(page).to have_text("95% likelihood")
    expect(page).to have_text("600,000 € impact")
    expect(page).to have_css(".op-risk-top-risks .op-status-badge", text: "Evaluated")
    expect(page).to have_css(".op-risk-top-risks .Label", text: "Response: Mitigate")
    expect(page).to have_no_heading("Mitigation coverage")
    expect(page).to have_heading("Risks requiring attention")
    expect(page).to have_no_link("0 without owner")
    expect(page).to have_no_css(".op-risk-response canvas")
    expect(page).to have_no_button("Last 30 days")
    expect(page).to have_no_text("Status by category")
    expect(page).to have_no_text("Risk development")
    expect(page).to have_link("Supplier outage")
    expect(page).to have_css(".op-border-box-grid__header", text: "Risk category")
    expect(page).to have_css(".op-border-box-grid__header", text: "Risk value")
    expect(page).to have_css(".Label", text: "Strategic")
    expect(page).to have_css(".op-border-box-grid__header", text: "Risk owner")
    expect(page).to have_css("[data-test-selector='risk-row-more-#{risk.id}']")
    expect(page).to have_link("Open details", visible: :all)
    expect(page).to have_link("Open fullscreen", visible: :all)
    expect(page).to have_link("Add to agenda", visible: :all)
    expect(page).to have_button("Status")
    expect(page).to have_button("Risk category")
    expect(page).to have_button("Risk response")
    expect(page).to have_button("All filters")
    expect(page).to have_link("Risk", href: new_project_work_packages_dialog_path(project, type_id: risk_type.id))

    find(".op-risk-matrix__cell", text: "1").click

    expect(page).to have_link("Supplier outage")
    expect(page).to have_no_link("Minor documentation issue")
    expect(page).to have_css(".op-risk-matrix__cell[aria-checked='true']", count: 1)
    expect(page).to have_heading("Risks", exact: true)
    expect(page).to have_no_css(".op-risk-log-active-filters")
    expect(page).to have_link("Clear all filters", href: project_risk_log_path(project))

    first(".op-risk-matrix__cell[aria-checked='false']").click

    expect(page).to have_css(".op-risk-matrix__cell[aria-checked='true']", count: 2)
    expect(page).to have_current_path(/risk_cells=/)

    all(:link, "Supplier outage").last.click

    expect(page).to have_current_path(project_risk_log_details_path(project, risk), ignore_query: true)
    expect(page).to have_css("turbo-frame#content-bodyRight")
  end

  it "provides the standard project submenu queries" do
    visit project_risk_log_menu_path(project)

    expect(page).to have_link("Newly added (7 days)", href: project_risk_log_path(project, view: "newly_added"))
    expect(page).to have_link("Requires attention", href: project_risk_log_path(project, view: "attention"))
    expect(page).to have_link("Without mitigation plan", href: project_risk_log_path(project, view: "without_mitigation"))
    expect(page).to have_link("Without owner", href: project_risk_log_path(project, view: "without_owner"))
    expect(page).to have_link("Not evaluated", href: project_risk_log_path(project, view: "not_evaluated"))
    expect(page).to have_no_link("High or critical risks")
    expect(page).to have_link("Occurred", href: project_risk_log_path(project, view: "occurred"))
    expect(page).to have_link("Closed", href: project_risk_log_path(project, view: "closed"))
    expect(page).to have_link("Last updated", href: project_risk_log_path(project, view: "last_updated"))
    expect(page).to have_link("Created by me", href: project_risk_log_path(project, view: "created_by_me"))
  end

  it "renders the dashboard when the project has no risks" do
    risk.destroy!
    low_risk.destroy!

    visit project_risk_log_path(project)

    expect(page).to have_heading("Risk log")
    expect(page).to have_heading("Top risk exposure")
    expect(page).to have_text("No evaluated monitored risks available.")
    expect(page).to have_css(".op-risk-matrix__cell", count: 25)
    expect(page).to have_heading("Risks", exact: true)
  end

  it "shows configuration guidance when the built-in risk type is missing" do
    risk_type.update!(builtin_identifier: nil)

    visit project_risk_log_path(project)

    expect(page).to have_heading("Risk log")
    expect(page).to have_text("The built-in Risk work package type is not available.")
    expect(page).to have_link("Configure risk management")
  end

  it "reflects selected matrix cells from the URL" do
    visit project_risk_log_path(project, risk_cells: "5:5")

    expect(page).to have_css(".op-risk-matrix__cell[aria-checked='true']", count: 1)
    expect(page).to have_link("Supplier outage")
    expect(page).to have_heading("Risks", exact: true)
  end

  it "keeps matrix axes and mitigation metrics synchronized with the risk list" do
    visit project_risk_log_path(project)

    find(".op-risk-matrix__row-label a", text: "Very high", exact_text: true).click

    expect(page).to have_css(".op-risk-matrix__cell[aria-checked='true']", count: 5)
    expect(page).to have_css(".op-risk-matrix__row-label a[aria-current='true']", text: "Very high")
    expect(page).to have_link("Supplier outage")
    expect(page).to have_no_link("Minor documentation issue")

    find(".op-risk-matrix__column-label a", text: "Very high", exact_text: true).click

    expect(page).to have_css(".op-risk-matrix__cell[aria-checked='true']", count: 9)
    expect(page).to have_css(".op-risk-matrix__column-label a[aria-current='true']", text: "Very high")

    first(".op-risk-metrics__link", text: "1").click

    expect(page).to have_current_path(/view=monitored/)
    expect(page).to have_link("Supplier outage")
    expect(page).to have_no_link("Minor documentation issue")
  end

  it "opens and closes the split view from the risk list toolbar" do
    visit project_risk_log_path(project)

    find("[data-test-selector='risk-log-split-view-toggle']").click

    expect(page).to have_current_path(project_risk_log_details_path(project, risk), ignore_query: true)
    expect(page).to have_css("turbo-frame#content-bodyRight > *")
    expect(page).to have_css(
      "[data-test-selector='risk-log-split-view-toggle']" \
      "[href='#{project_risk_log_path(project)}']"
    )

    find("[data-test-selector='risk-log-split-view-toggle']").click

    expect(page).to have_current_path(project_risk_log_path(project), ignore_query: true)
    expect(page).to have_no_css("turbo-frame#content-bodyRight > *")
    expect(page).to have_css(
      "[data-test-selector='risk-log-split-view-toggle']" \
      "[href='#{project_risk_log_details_path(project, risk)}']"
    )
  end

  it "passes automated accessibility checks", :js, :selenium, driver: :firefox_en do
    visit project_risk_log_path(project)

    expect(page).to be_axe_clean.within("#content")
  end
end
