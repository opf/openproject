# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Risk management admin settings" do
  current_user { create(:admin) }
  let!(:risk_type) { create(:type, builtin_identifier: "risk") }

  before { Setting.plugin_openproject_risk_management = {} }

  it "configures the impact thresholds" do
    visit risk_management_admin_settings_path

    fill_in I18n.t("risk_management.admin.impact_thresholds.impact_very_low_max.label"), with: 10_000
    fill_in I18n.t("risk_management.admin.impact_thresholds.impact_low_max.label"), with: 50_000
    fill_in I18n.t("risk_management.admin.impact_thresholds.impact_medium_max.label"), with: 100_000
    fill_in I18n.t("risk_management.admin.impact_thresholds.impact_high_max.label"), with: 500_000
    click_button I18n.t(:button_save)

    expect(page).to have_text(I18n.t(:notice_successful_update))
    Setting.clear_cache
    expect(RiskManagement::Configuration.load).to have_attributes(
      impact_very_low_max: 10_000,
      impact_low_max: 50_000,
      impact_medium_max: 100_000,
      impact_high_max: 500_000
    )
  end

  it "manages the core risk categories" do
    visit risk_management_admin_settings_path
    click_link "Manage risk categories"
    find_link("New risk category", href: new_risk_management_admin_category_path, match: :first).click

    fill_in "Name", with: "Environmental"
    check "Active"
    click_button I18n.t(:button_save)

    expect(page).to have_text(I18n.t(:notice_successful_update))
    expect(page).to have_text("Environmental")
    expect(RiskManagement::RiskCategory.find_by(name: "Environmental")).to be_active
  end
end
