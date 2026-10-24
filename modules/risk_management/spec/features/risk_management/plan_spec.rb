# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Risk management plan" do
  current_user { create(:admin) }

  let(:project) { create(:project, enabled_module_names: %w[work_package_tracking risk_log]) }
  let!(:plan) do
    RiskManagement::Plan.create!(
      project:,
      author: current_user,
      updated_by: current_user,
      body: "# Risk management plan\n\n## Identification\nRisks are reviewed weekly."
    )
  end

  it "shows the independent plan and its edit form" do
    visit project_risk_management_plan_path(project)

    expect(page).to have_heading("Risk management plan")
    expect(page).to have_text("Identification")
    expect(page).to have_link("Risk log", href: project_risk_log_path(project))

    find_link(I18n.t(:button_edit), href: project_edit_risk_management_plan_path(project), match: :first).click

    expect(find("textarea[name='risk_management_plan[body]']", visible: :all).value).to eq(plan.body)
  end
end
