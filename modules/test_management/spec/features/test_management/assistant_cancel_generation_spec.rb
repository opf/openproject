# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Cancel assistant generation", :js do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases use_test_assistant]
           })
  end
  shared_let(:generation) do
    create(:tm_assistant_generation, project:, user:, status: "running")
  end

  current_user { user }

  it "cancels a pending generation from the generation page" do
    visit project_test_management_assistant_generation_path(project, generation)

    find("[data-test-selector='tm-assistant-generation-cancel']").click

    expect(page).to have_css("[data-test-selector='tm-assistant-generation-cancelled'], [data-test-selector='tm-assistant-generation-cancel']",
                             wait: 10)
    expect(generation.reload.status).to eq("cancelled")
  end
end
