require "spec_helper"

RSpec.describe "Zen mode", :js do
  let(:dev_role) do
    create(:project_role,
           permissions: %i[view_work_packages
                           edit_work_packages])
  end
  let(:dev) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_roles: { project => dev_role })
  end

  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }

  let(:work_package) do
    create(:work_package, project:, type:)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  let(:status_from) { work_package.status }
  let(:status_intermediate) { create(:status) }

  before do
    login_as(dev)

    work_package

    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  it "hides menus" do
    wp_page.expect_no_zen_mode
    wp_page.page.find_by_id("work-packages-zen-mode-toggle-button").click
    wp_page.expect_zen_mode
    wp_page.go_back
    wp_page.expect_zen_mode
    wp_page.page.find_by_id("work-packages-zen-mode-toggle-button").click
    wp_page.expect_no_zen_mode
  end
end
