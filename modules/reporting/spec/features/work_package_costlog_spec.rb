require "spec_helper"

RSpec.describe "Cost report showing my own times", :js do
  let(:project) { create(:project) }
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i[view_work_packages view_own_cost_entries] }

  let(:budget) do
    create(:budget, project:)
  end
  let(:cost_type) { create(:cost_type, name: "Foobar", unit: "Foobar", unit_plural: "Foobars") }
  let(:work_package) { create(:work_package, project:, budget:) }
  let(:wp_page) { Pages::FullWorkPackage.new work_package, project }

  let(:cost_entry) do
    build(:cost_entry,
          cost_type:,
          project:,
          work_package:,
          spent_on: Date.today,
          units: "10",
          user:,
          comments: "foobar")
  end

  before do
    login_as user
    cost_entry.save!
    wp_page.visit!
  end

  it "allows visiting the costs which redirects to cost reports" do
    new_window = window_opened_by do
      page.find(".costsByType a", text: "10 Foobar").click
    end

    within_window new_window do
      expect(page).to have_css("#query_saved_name", text: "New cost report")
      expect(page).to have_field("values[work_package_id][]", with: work_package.id)
      expect(page).to have_css("td.units", text: "10.0 Foobars")
    end
  end
end
