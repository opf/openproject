require "spec_helper"

RSpec.describe "Cost report in subproject", :js do
  let!(:project) { create(:project) }
  let!(:subproject) { create(:project, parent: project) }

  let!(:role) { create(:project_role, permissions: %i(view_cost_entries view_own_cost_entries)) }
  let!(:user) do
    create(:user,
           member_with_roles: { subproject => role })
  end

  before do
    login_as(user)
    visit project_path(subproject)
  end

  it "provides filtering" do
    within "#main-menu" do
      click_on "Time and costs"
    end

    within "#content" do
      expect(page).to have_content "New cost report"
    end
  end
end
