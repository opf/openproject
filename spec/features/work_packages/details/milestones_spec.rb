require "spec_helper"

RSpec.describe "Milestones full screen v iew", :js do
  let(:type) { create(:type, is_milestone: true) }
  let(:project) { create(:project, types: [type]) }
  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           subject: "Foobar")
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:button) { find(".add-work-package", wait: 5) }

  before do
    login_as(user)
    wp_page.visit!
  end

  context "user has :add_work_packages permission" do
    let(:user) do
      create(:user, member_with_roles: { project => role })
    end
    let(:role) { create(:project_role, permissions:) }
    let(:permissions) do
      %i[view_work_packages add_work_packages]
    end

    it "shows the button as enabled" do
      expect(button).not_to be_disabled

      button.click
      expect(page).to have_css(".menu-item", text: type.name.upcase)
    end
  end

  context "user has :view_work_packages permission only" do
    let(:user) do
      create(:user, member_with_roles: { project => role })
    end
    let(:role) { create(:project_role, permissions:) }
    let(:permissions) do
      %i[view_work_packages]
    end

    it "shows the button as correctly disabled" do
      expect(button["disabled"]).to be_truthy
    end
  end
end
