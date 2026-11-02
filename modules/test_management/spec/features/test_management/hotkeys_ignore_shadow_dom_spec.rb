# frozen_string_literal: true

require "spec_helper"

# Document listeners retarget shadow-DOM keydowns to the host. Typing words that
# contain a shortcut sequence (e.g. "Introduction" → n t r) must not navigate.
RSpec.describe "Test management hotkeys in shadow DOM editors", :js do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs add_test_runs]
           })
  end

  current_user { user }

  it "ignores shortcut sequences typed inside a shadow textbox" do
    visit project_test_management_test_cases_path(project)
    expect(page).to have_css("#tm-hotkeys-config", visible: :all)

    page.execute_script(<<~JS)
      const host = document.createElement("op-block-note");
      const root = host.attachShadow({ mode: "open" });
      const box = document.createElement("div");
      box.setAttribute("role", "textbox");
      box.contentEditable = "true";
      root.appendChild(box);
      document.body.appendChild(host);
      box.focus();
    JS

    page.send_keys("n", "t", "r")

    expect(page).to have_current_path(project_test_management_test_cases_path(project), ignore_query: true)
    expect(page).to have_no_current_path(%r{/test_management/test_runs/new})
  end
end
