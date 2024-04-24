require "spec_helper"
require "features/page_objects/notification"

RSpec.describe "edit work package", :js do
  let(:current_user) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_permissions: { project => permissions })
  end
  let(:permissions) { %i[view_work_packages assign_versions] }

  let(:cf_all) do
    create(:work_package_custom_field, is_for_all: true, field_format: "text")
  end

  let(:type) { create(:type, custom_fields: [cf_all]) }
  let(:project) { create(:project, types: [type]) }
  let(:work_package) do
    create(:work_package,
           author: current_user,
           project:,
           type:,
           created_at: 5.days.ago.to_date.to_fs(:db))
  end
  let(:status) { work_package.status }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:version) { create(:version, project:) }

  def visit!
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  before do
    login_as(current_user)

    visit!
  end

  context "as a user having only the assign_versions permission" do
    it "can only change the version" do
      wp_page.update_attributes version: version.name

      wp_page.expect_toast(message: "Successful update")
      wp_page.expect_attributes version: version.name

      subject_field = wp_page.work_package_field("subject")
      subject_field.expect_read_only
    end
  end

  context "as a user having only the edit_work_packages permission" do
    let(:permissions) { %i[view_work_packages edit_work_packages] }

    it "can not change the version" do
      version_field = wp_page.work_package_field("version")
      version_field.expect_read_only
    end
  end
end
