# frozen_string_literal: true

require "spec_helper"

# 0019: keyboard shortcuts, badges, tips and their switches.
RSpec.describe "Test management keyboard shortcuts", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:plain_project) { create(:project, enabled_module_names: %i[work_package_tracking]) }
  shared_let(:admin) { create(:admin) }

  let(:permissions) { %i[view_test_cases add_test_cases view_test_runs add_test_runs] }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions, plain_project => %i[view_work_packages] })
  end
  let(:current_user) { user }

  before { login_as(current_user) }
  after { Setting.plugin_openproject_test_management = {} }

  def html
    response.parsed_body
  end

  def config
    node = html.at_css("#tm-hotkeys-config")
    node && JSON.parse(node["data-config"])
  end

  def shortcut_ids
    config.fetch("shortcuts").pluck("id")
  end

  describe "on Test management pages" do
    it "renders the config, the dialog and the nonced script" do
      get project_test_management_test_cases_path(project)

      expect(response).to have_http_status(:ok)
      expect(shortcut_ids).to eq(%w[cases runs new_case new_run help])
      expect(config["timeout"]).to eq(1000)
      script = html.css("script[nonce]").find { |node| node.text.include?("__tmHotkeys") }
      expect(script).to be_present
      expect(html.css('[data-test-selector^="tm-hotkeys-row-"]').pluck("data-test-selector"))
        .to eq(%w[cases runs new_case new_run help].map { |id| "tm-hotkeys-row-#{id}" })
      expect(html.at_css('[data-test-selector="tm-hotkeys-prefs"]')).to be_present
    end

    it "shows the badges on Create and New test run" do
      get project_test_management_test_cases_path(project)
      expect(html.at_css('[data-test-selector="tm-new-test-case"] [data-test-selector="tm-hotkey-badge-new_case"]').text)
        .to eq("n t c")

      get project_test_management_test_runs_path(project)
      expect(html.at_css('[data-test-selector="tm-new-run"] [data-test-selector="tm-hotkey-badge-new_run"]').text)
        .to eq("n t r")
    end

    it "renders a (hidden) tip with probability and cooldown for the browser" do
      get project_test_management_test_runs_path(project)

      tip = html.at_css('[data-test-selector="tm-hotkey-tip"]')
      expect(tip).to be_present
      expect(tip["hidden"]).not_to be_nil
      expect(tip["data-probability"]).to eq("0.35")
      expect(tip["data-cooldown-minutes"]).to eq("10")
      expect(shortcut_ids).to include(tip["data-tip-id"])
      expect(tip.css("kbd.tm-kbd")).to be_present
      expect(tip.at_css('[data-test-selector="tm-hotkey-tip-dismiss"]')["data-url"]).to eq("/test_management/hotkey_preferences")
    end

    it "offers 'u' where the page has a parent" do
      run = create(:tm_test_run, project:)
      get project_test_management_test_run_path(project, run)

      up = config["shortcuts"].find { |entry| entry["id"] == "up" }
      expect(up).to include("keys" => "u", "href" => project_test_management_test_runs_path(project))
    end
  end

  describe "permissions" do
    let(:permissions) { %i[view_test_cases] }

    it "only offers what the user may open" do
      get project_test_management_test_cases_path(project)

      expect(shortcut_ids).to eq(%w[cases help])
      expect(html.at_css('[data-test-selector="tm-hotkey-badge-new_case"]')).to be_nil
    end
  end

  describe "other pages of the project" do
    it "binds the project shortcuts without tips and 'u' (like core n w p)" do
      get project_overview_path(project)

      expect(response).to have_http_status(:ok)
      expect(shortcut_ids).to include("cases", "runs", "new_case")
      expect(shortcut_ids).not_to include("up")
      expect(html.at_css('[data-test-selector="tm-hotkey-tip"]')).to be_nil
    end

    it "renders nothing in projects without the module" do
      get project_overview_path(plain_project)

      expect(response).to have_http_status(:ok)
      expect(html.at_css("#tm-hotkeys-config")).to be_nil
      expect(response.body).not_to include("__tmHotkeys")
    end
  end

  describe "switches" do
    it "renders nothing when the user disabled keyboard shortcuts" do
      user.pref.update!(disable_keyboard_shortcuts: true)
      get project_test_management_test_cases_path(project)

      expect(html.at_css("#tm-hotkeys-config")).to be_nil
      expect(html.at_css('[data-test-selector="tm-hotkey-badge-new_case"]')).to be_nil
    end

    it "renders nothing when an admin switched the shortcuts off" do
      Setting.plugin_openproject_test_management = { "hotkeys_enabled" => false }
      get project_test_management_test_cases_path(project)

      expect(html.at_css("#tm-hotkeys-config")).to be_nil
    end

    it "keeps the shortcuts but drops badges and tips when an admin switched hints off" do
      Setting.plugin_openproject_test_management = { "hotkey_hints_enabled" => false }
      get project_test_management_test_cases_path(project)

      expect(config["hints"]).to be(false)
      expect(html.at_css('[data-test-selector="tm-hotkey-badge-new_case"]')).to be_nil
      expect(html.at_css('[data-test-selector="tm-hotkey-tip"]')).to be_nil
      expect(html.at_css('[data-test-selector="tm-hotkeys-prefs"]')).to be_nil
    end

    it "drops the tips after 'Don't show tips again' (JSON) and keeps the badges" do
      patch test_management_hotkey_preferences_path, params: { hotkey_tips: false }.to_json,
                                                     headers: { "CONTENT_TYPE" => "application/json",
                                                                "ACCEPT" => "application/json" }
      expect(response).to have_http_status(:no_content)
      expect(TestManagement::UserPreference.for(user)).not_to be_hotkey_tips_enabled

      get project_test_management_test_cases_path(project)
      expect(html.at_css('[data-test-selector="tm-hotkey-tip"]')).to be_nil
      expect(html.at_css('[data-test-selector="tm-hotkey-badge-new_case"]')).to be_present
      expect(html.at_css("#tm-hotkey-pref-tips")["checked"]).to be_nil
    end

    it "saves both switches from the dialog form and goes back" do
      patch test_management_hotkey_preferences_path,
            params: { hotkey_tips: "1", hotkey_hints: "0" },
            headers: { "HTTP_REFERER" => project_test_management_test_cases_path(project) }
      expect(response).to redirect_to(project_test_management_test_cases_path(project))

      get project_test_management_test_cases_path(project)
      expect(html.at_css('[data-test-selector="tm-hotkey-badge-new_case"]')).to be_nil
      expect(html.at_css('[data-test-selector="tm-hotkey-tip"]')).to be_present
      expect(config["hints"]).to be(false)
    end

    it "does not touch core preferences" do
      patch test_management_hotkey_preferences_path, params: { hotkey_tips: "0" }
      expect(user.reload.pref.settings.keys.map(&:to_s)).not_to include("hotkey_tips")
    end

    context "as anonymous" do
      let(:current_user) { User.anonymous }

      it "cannot store preferences" do
        patch test_management_hotkey_preferences_path, params: { hotkey_tips: "0" },
                                                       headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
        expect(TestManagement::UserPreference.count).to eq(0)
      end
    end
  end

  describe "admin settings" do
    let(:current_user) { admin }

    it "shows and saves the shortcut switches" do
      get test_management_admin_settings_path
      expect(html.at_css('[data-test-selector="tm-admin-hotkeys"]')).to be_present
      expect(html.at_css('input[type="checkbox"][name="hotkeys_enabled"]')["checked"]).to be_present

      patch test_management_admin_settings_path,
            params: { default_display_prefix: "TC", hotkeys_enabled: "1", hotkey_hints_enabled: "0" }
      expect(response).to redirect_to(test_management_admin_settings_path)
      expect(Setting.plugin_openproject_test_management["hotkeys_enabled"]).to be(true)
      expect(Setting.plugin_openproject_test_management["hotkey_hints_enabled"]).to be(false)
      expect(TestManagement::Hotkeys).not_to be_hints_enabled
    end
  end
end
