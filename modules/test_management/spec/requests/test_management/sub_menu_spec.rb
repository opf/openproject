# frozen_string_literal: true

require "spec_helper"

# 0018: Test management behaves like Work packages, Documents and Meetings in the project menu:
# a "→" arrow on the main entry, a "← Test management" header and a lazy-loaded submenu.
RSpec.describe "Test management sidebar submenu", type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs use_test_assistant] })
  end

  let(:current_user) { user }

  before { login_as(current_user) }

  def frame_src
    response.parsed_body.at_css("turbo-frame#test_management_sub_menu")&.[]("src")
  end

  def submenu
    response.parsed_body
  end

  describe "main menu" do
    it "shows the arrow, the back header and the submenu frame for the current section" do
      get project_test_management_test_cases_path(project)

      expect(response).to have_http_status(:ok)
      html = response.parsed_body
      entry = html.at_css('li[data-name="test_management"]')
      expect(entry["class"]).to include("open")
      expect(entry.at_css('[data-test-selector="main-menu-toggler--test_management"]')).to be_present
      expect(entry.at_css('[data-test-selector="main-menu--arrow-left-to-project"]')).to be_present
      expect(entry.at_css(".main-menu--parent-node").text).to include("Test management")
      expect(frame_src).to include("/projects/#{project.identifier}/test_management/menu")
      expect(frame_src).to include("section=cases")
    end

    it "has no flat child entries any more" do
      get project_test_management_test_cases_path(project)

      %w[test_management_cases test_management_runs test_management_folder_tree test_management_reports].each do |name|
        expect(response.body).not_to include(%(data-name="#{name}"))
      end
    end

    it "passes the section of runs and the assistant" do
      get project_test_management_test_runs_path(project)
      expect(frame_src).to include("section=runs")

      get project_test_management_assistant_path(project)
      expect(frame_src).to include("section=assistant")
    end
  end

  describe "GET menu" do
    it "lists the sections and highlights the current one" do
      get project_test_management_menu_path(project, section: "runs")

      expect(response).to have_http_status(:ok)
      links = submenu.css('[data-test-selector="op-submenu--item-action"]')
      expect(links.map { it.text.squish }).to eq(["Cases", "Test Assistant", "Runs", "Plans", "Milestones"])
      expect(links.select { it["class"].include?("selected") }.map { it.text.squish }).to eq(["Runs"])
    end

    context "with view_test_cases only" do
      let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

      it "hides what the user may not open" do
        get project_test_management_menu_path(project, section: "cases")

        expect(submenu.css('[data-test-selector="op-submenu--item-action"]').map { it.text.squish })
          .to eq(%w[Cases])
      end
    end

    it "shows the folder tree on the Cases section with the sidebar layout only" do
      create(:tm_project_setting, project:, folder_tree_layout: "sidebar")
      create(:tm_suite, project:, name: "Accounts")

      get project_test_management_menu_path(project, section: "cases")
      expect(submenu.at_css('[data-test-selector="tm-sub-menu-folders"]')).to be_present
      expect(response.body).to include("Accounts")

      get project_test_management_menu_path(project, section: "runs")
      expect(submenu.at_css('[data-test-selector="tm-sub-menu-folders"]')).to be_nil
    end

    it "keeps the folder tree in the page with the split pane layout" do
      create(:tm_suite, project:, name: "Accounts")

      get project_test_management_menu_path(project, section: "cases")
      expect(submenu.at_css('[data-test-selector="tm-sub-menu-folders"]')).to be_nil
    end

    context "without access to the module" do
      let(:current_user) { create(:user) }

      it "is refused" do
        get project_test_management_menu_path(project, section: "cases")
        expect(response.status).to be_in([403, 404])
      end
    end
  end
end
