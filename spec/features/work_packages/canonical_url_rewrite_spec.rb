# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work package canonical URL rewrite",
               :js,
               :with_cuprite,
               with_settings: { work_packages_identifier: "semantic" } do
  shared_let(:admin) { create(:admin) }
  let(:project) { create(:project, enabled_module_names: %w[work_package_tracking wiki]) }
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

      expect(page).to have_current_path(semantic_path)
    end
  end

  describe "after Turbo Drive navigation (turbo:render)" do
    let!(:wiki_page) do
      create(:wiki_page,
             wiki: project.wiki,
             title: "Wiki page with work package link",
             text: "See [the work package](#{numeric_path}) for details.")
    end

    it "rewrites a numeric ID in a followed user-content link to the canonical semantic ID" do
      visit project_wiki_path(project, wiki_page)
      expect(page).to have_css(".wiki-content")

      wait_for_turbo do
        within(".wiki-content") { click_link "the work package" }
      end

      expect(page).to have_current_path(semantic_path)
      full_screen.ensure_page_loaded
    end
  end

  describe "back button" do
    it "single back press returns to the previous page — replaceState leaves no phantom entry" do
      visit project_path(project)

      visit numeric_path
      expect(page).to have_current_path(semantic_path)

      page.go_back

      expect(page).to have_current_path(project_path(project))
    end

    it "back navigation after Turbo cache restoration shows the canonical URL and restores from cache" do
      visit numeric_path
      expect(page).to have_current_path(semantic_path)

      # Navigate away via Turbo Drive (caches the WP page snapshot under the semantic URL).
      wait_for_turbo { page.execute_script("Turbo.visit(#{project_path(project).to_json})") }
      expect(page).to have_current_path(project_path(project))

      # Record the visit action and any page-level (non-frame) Turbo fetch that fires
      # on the way back. Drive page fetches dispatch turbo:before-fetch-request on
      # document.documentElement; frame fetches dispatch on the <turbo-frame> element.
      page.execute_script(<<~JS)
        document.addEventListener("turbo:visit",
          (event) => { window.__opBackVisitAction = event.detail.action }, { once: true });
        window.__opPageFetches = [];
        document.addEventListener("turbo:before-fetch-request", (event) => {
          if (!(event.target instanceof HTMLElement && event.target.tagName === "TURBO-FRAME")) {
            window.__opPageFetches.push(event.detail.url.toString());
          }
        });
      JS

      wait_for_turbo { page.go_back }

      # action == "restore" proves Turbo's history state survived the rewrite;
      # the empty page-fetch list proves the snapshot cache was hit (no re-fetch).
      expect(page.evaluate_script("window.__opBackVisitAction")).to eq("restore")
      expect(page.evaluate_script("window.__opPageFetches")).to be_empty
      expect(page).to have_current_path(semantic_path)
      full_screen.expect_subject
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
