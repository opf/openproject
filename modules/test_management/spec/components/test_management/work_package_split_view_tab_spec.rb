# frozen_string_literal: true

require "spec_helper"

# The split view tab bar is rendered server-side from the
# :work_package_split_view menu, not from the Angular tab registry.
RSpec.describe WorkPackages::Details::TabComponent, "Testing tab", type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:plain_project) { create(:project, enabled_module_names: %i[work_package_tracking]) }
  shared_let(:tester) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages view_test_cases show_testing_content],
             plain_project => %i[view_work_packages show_testing_content]
           })
  end
  shared_let(:reader) { create(:user, member_with_permissions: { project => %i[view_work_packages view_test_cases] }) }

  let(:work_package) { create(:work_package, project:) }
  let(:current_user) { tester }

  before { login_as(current_user) }

  def render_tabs(wp = work_package)
    with_controller_class(NotificationsController) do
      with_request_url("/notifications/details/:work_package_id") do
        render_inline(described_class.new(work_package: wp, base_route: notifications_path))
      end
    end
  end

  it "shows the Testing tab with the linked case count" do
    create(:tm_test_case_work_package, test_case: create(:tm_test_case, project:), work_package:)

    render_tabs

    expect(page).to have_test_selector("wp-details-tab-component--tab-testing", text: "Testing")
    expect(page).to have_test_selector("wp-details-tab-component--testing-counter", text: "1")
  end

  it "hides the tab where the module is disabled" do
    render_tabs(create(:work_package, project: plain_project))
    expect(page).not_to have_test_selector("wp-details-tab-component--tab-testing")
  end

  context "without show_testing_content" do
    let(:current_user) { reader }

    it "hides the tab" do
      render_tabs
      expect(page).not_to have_test_selector("wp-details-tab-component--tab-testing")
    end
  end
end
