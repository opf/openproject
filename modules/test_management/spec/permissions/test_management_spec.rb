# frozen_string_literal: true

require "spec_helper"
require "support/permission_specs"

RSpec.describe TestManagement::WorkPackageTestingTabController, "show_testing_content permission" do
  it "maps the tab actions to :show_testing_content" do
    permission = OpenProject::AccessControl.permission(:show_testing_content)

    expect(permission.controller_actions)
      .to include("test_management/work_package_testing_tab/index", "test_management/work_package_testing_tab/count")
    expect(permission.permissible_on).to include(:work_package, :project)
  end
end
