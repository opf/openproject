# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Hotkeys::Page do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[work_package_tracking]) }

  let(:permissions) { %i[view_test_cases add_test_cases view_test_runs add_test_runs use_test_assistant] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:assigns) { {} }

  def page(controller_path: "test_management/test_cases", action_name: "index", params: {}, for_project: project)
    described_class.new(project: for_project, user:, controller_path:, action_name:,
                        params: ActionController::Parameters.new(params), assigns: ->(name) { assigns[name] })
  end

  def ids(page)
    page.shortcuts.pluck(:id)
  end

  before do
    allow(Setting).to receive(:plugin_openproject_test_management).and_return({})
  end

  describe "#shortcuts" do
    it "offers every shortcut the user may use, with targets" do
      # A test case page has a parent (the Cases list in the case's folder), so "u" is offered too.
      assigns[:test_case] = create(:tm_test_case, project:, suite: create(:tm_suite, project:))
      shortcuts = page(action_name: "show", params: { id: assigns[:test_case].id })
                    .shortcuts.to_h { |entry| [entry[:id], entry[:href]] }

      expect(shortcuts.keys).to eq(%w[cases runs assistant new_case new_run up help])
      expect(shortcuts["up"])
        .to eq("/projects/#{project.identifier}/test_management/test_cases?suite_id=#{assigns[:test_case].suite_id}")
      expect(shortcuts["cases"]).to eq("/projects/#{project.identifier}/test_management/test_cases")
      expect(shortcuts["runs"]).to eq("/projects/#{project.identifier}/test_management/test_runs")
      expect(shortcuts["assistant"]).to eq("/projects/#{project.identifier}/test_management/assistant")
      expect(shortcuts["new_case"]).to eq("/projects/#{project.identifier}/test_management/test_cases/new")
      expect(shortcuts["new_run"]).to eq("/projects/#{project.identifier}/test_management/test_runs/new")
    end

    it "offers the same shortcuts without 'u' on the root Cases list" do
      expect(ids(page)).to eq(%w[cases runs assistant new_case new_run help])
    end

    context "with view permissions only" do
      let(:permissions) { %i[view_test_cases] }

      it "drops the shortcuts of other permissions" do
        expect(ids(page)).to eq(%w[cases help])
      end
    end

    context "with the Test Assistant switched off for the project" do
      before { create(:tm_project_setting, project:, enable_test_assistant: false) }

      it "drops 'g t a'" do
        expect(ids(page)).not_to include("assistant")
      end
    end

    it "keeps the project shortcuts on other pages of the project, without 'up'" do
      other = page(controller_path: "work_packages", action_name: "index")
      expect(other).to be_active
      expect(other).not_to be_module_page
      expect(ids(other)).to include("cases", "new_case", "help")
      expect(ids(other)).not_to include("up")
    end

    it "carries the current folder into 'new test case'" do
      assigns[:current_suite] = create(:tm_suite, project:)
      new_case = page(params: { suite_id: assigns[:current_suite].id }).shortcut(:new_case)
      expect(new_case[:href]).to end_with("/test_cases/new?suite_id=#{assigns[:current_suite].id}")
    end
  end

  describe "#active?" do
    it "is off outside projects and in projects without the module" do
      expect(page(for_project: nil)).not_to be_active
      expect(page(for_project: other_project)).not_to be_active
    end

    it "is off for users without any Test management permission" do
      stranger = create(:user)
      expect(described_class.new(project:, user: stranger, controller_path: "projects", action_name: "show")).not_to be_active
    end

    it "is off when the user disabled keyboard shortcuts (core preference)" do
      user.pref.update!(disable_keyboard_shortcuts: true)
      expect(page).not_to be_active
    end

    it "is off when an admin switched the shortcuts off" do
      allow(Setting).to receive(:plugin_openproject_test_management).and_return("hotkeys_enabled" => false)
      expect(page).not_to be_active
    end
  end

  describe "#up_path ('u')" do
    let(:base) { "/projects/#{project.identifier}/test_management" }
    let(:parent_folder) { create(:tm_suite, project:) }
    let(:folder) { create(:tm_suite, project:, parent: parent_folder) }

    it "goes from a test case to its folder" do
      assigns[:test_case] = create(:tm_test_case, project:, suite: folder)
      expect(page(action_name: "show").up_path).to eq("#{base}/test_cases?suite_id=#{folder.id}")
    end

    it "goes from editing a case to the case" do
      assigns[:test_case] = create(:tm_test_case, project:)
      expect(page(action_name: "edit").up_path).to eq("#{base}/test_cases/#{assigns[:test_case].id}")
    end

    it "goes from a folder to its parent folder, and from a top-level folder to all cases" do
      assigns[:current_suite] = folder
      expect(page(params: { suite_id: folder.id }).up_path).to eq("#{base}/test_cases?suite_id=#{parent_folder.id}")

      assigns[:current_suite] = parent_folder
      expect(page(params: { suite_id: parent_folder.id }).up_path).to eq("#{base}/test_cases")
    end

    it "has no target on the root lists, so 'u' is not offered" do
      expect(page.up_path).to be_nil
      expect(ids(page)).not_to include("up")
      expect(page(controller_path: "test_management/test_runs").up_path).to be_nil
      expect(page(controller_path: "test_management/assistant", action_name: "show").up_path).to be_nil
    end

    it "goes from a run to the runs list and from editing a run to the run" do
      assigns[:test_run] = create(:tm_test_run, project:)
      expect(page(controller_path: "test_management/test_runs", action_name: "show").up_path).to eq("#{base}/test_runs")
      expect(page(controller_path: "test_management/test_runs", action_name: "edit").up_path)
        .to eq("#{base}/test_runs/#{assigns[:test_run].id}")
      expect(ids(page(controller_path: "test_management/test_runs", action_name: "show"))).to include("up")
    end

    it "goes from a sub-milestone to its parent and from a milestone to the list" do
      parent = create(:tm_milestone, project:)
      assigns[:milestone] = create(:tm_milestone, project:, parent:)
      expect(page(controller_path: "test_management/milestones", action_name: "show").up_path)
        .to eq("#{base}/milestones/#{parent.id}")

      assigns[:milestone] = parent
      expect(page(controller_path: "test_management/milestones", action_name: "show").up_path).to eq("#{base}/milestones")
    end

    it "goes from the CI trigger form back to where it was opened" do
      assigns[:test_case] = create(:tm_test_case, project:)
      expect(page(controller_path: "test_management/ci_triggers", action_name: "new").up_path)
        .to eq("#{base}/test_cases/#{assigns[:test_case].id}")
    end

    it "is not offered on non-module pages" do
      expect(page(controller_path: "test_management/project_settings", action_name: "show").up_path).to be_nil
    end
  end

  describe "hints and tips" do
    it "shows both by default on module pages" do
      expect(page).to be_hints
      expect(page).to be_tips
    end

    it "shows no tips outside module pages" do
      expect(page(controller_path: "work_packages")).not_to be_tips
    end

    it "respects the user's choices" do
      TestManagement::UserPreference.for(user).assign_options(hotkey_tips: false, hotkey_hints: false).save!
      expect(page).not_to be_tips
      expect(page).not_to be_hints
      expect(page).to be_active
    end

    it "respects the admin switch" do
      allow(Setting).to receive(:plugin_openproject_test_management).and_return("hotkey_hints_enabled" => false)
      expect(page).not_to be_tips
      expect(page).not_to be_hints
      expect(page).to be_active
    end

    it "picks a tip among the available shortcuts, never the list itself" do
      tips = Array.new(30) { |i| page.tip(random: Random.new(i))[:id] }.uniq
      expect(tips - page.shortcuts.pluck(:id)).to eq([])
      expect(tips).not_to include("help")
      expect(tips.size).to be > 1
    end

    it "gives anonymous users no tips" do
      anonymous_page = described_class.new(project:, user: User.anonymous, controller_path: "test_management/test_cases",
                                           action_name: "index")
      expect(anonymous_page).not_to be_tips
    end
  end

  describe "#config" do
    it "contains the sequences, targets and the quick-create focus target" do
      config = page.config
      new_case = config[:shortcuts].find { |entry| entry[:id] == "new_case" }
      expect(new_case[:sequence]).to eq(%w[n t c])
      expect(new_case[:focus]).to eq("#tm-new-case-title")
      expect(config[:timeout]).to eq(1000)
      expect(config[:hints]).to be(true)
    end
  end
end
