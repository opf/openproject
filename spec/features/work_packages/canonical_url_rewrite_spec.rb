# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work package canonical URL rewrite",
               :js,
               :with_cuprite,
               with_settings: { work_packages_identifier: "semantic" } do
  shared_let(:admin) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:, subject: "Canonical URL test WP") }

  let(:full_screen) { Pages::FullWorkPackage.new(work_package, project) }

  before do
    work_package
    login_as admin
  end

  def numeric_path(tab = "activity")
    project_work_package_path(project, work_package.id, tab)
  end

  def semantic_path(tab = "activity")
    project_work_package_path(project, work_package.reload.identifier, tab)
  end

  describe "on initial page load (DOMContentLoaded)" do
    it "rewrites a numeric work package ID to the canonical semantic ID" do
      visit numeric_path
      wait_for_network_idle

      expect(page).to have_current_path(semantic_path)
    end
  end

  describe "after Turbo Drive navigation (turbo:render)" do
    it "rewrites a numeric work package ID to the canonical semantic ID" do
      visit project_path(project)
      wait_for_reload

      page.execute_script("Turbo.visit('#{numeric_path}')")
      wait_for_network_idle

      expect(page).to have_current_path(semantic_path)
    end
  end

  describe "back button" do
    it "single back press returns to the previous page — replaceState leaves no phantom entry" do
      visit project_path(project)
      wait_for_reload

      visit numeric_path
      wait_for_network_idle
      expect(page).to have_current_path(semantic_path)

      page.go_back
      wait_for_network_idle

      expect(page).to have_current_path(project_path(project))
    end

    it "back navigation after Turbo cache restoration shows the canonical URL" do
      visit numeric_path
      wait_for_network_idle
      expect(page).to have_current_path(semantic_path)

      # Navigate away via Turbo Drive (caches the WP page snapshot)
      page.execute_script("Turbo.visit('#{project_path(project)}')")
      wait_for_network_idle
      expect(page).to have_current_path(project_path(project))

      # Turbo restores from cache (fires turbo:render) — URL must still be canonical
      page.go_back
      wait_for_network_idle

      expect(page).to have_current_path(semantic_path)
    end
  end

  describe "Angular routing after URL rewrite" do
    it "tab navigation preserves the semantic ID — UI Router reads already-corrected URL" do
      visit numeric_path("activity")
      full_screen.ensure_page_loaded
      expect(page).to have_current_path(semantic_path("activity"))

      full_screen.switch_to_tab(tab: "relations")
      wait_for_network_idle

      expect(page).to have_current_path(semantic_path("relations"))
    end
  end
end
