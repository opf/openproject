#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

require_relative "../../support/pages/my/page"

RSpec.describe "Assigned to me embedded query on my page", :js do
  let!(:type) { create(:type) }
  let!(:priority) { create(:default_priority) }
  let!(:project) { create(:project, types: [type]) }
  let!(:open_status) { create(:default_status) }
  let!(:assigned_work_package) do
    create(:work_package,
           project:,
           subject: "Assigned to me",
           type:,
           author: user,
           assigned_to: user)
  end
  let!(:assigned_work_package_2) do
    create(:work_package,
           project:,
           subject: "My task 2",
           type:,
           author: user,
           assigned_to: user)
  end
  let!(:assigned_to_other_work_package) do
    create(:work_package,
           project:,
           subject: "Not assigned to me",
           type:,
           author: user,
           assigned_to: other_user)
  end
  let(:other_user) do
    create(:user)
  end

  let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_packages edit_work_packages save_queries work_package_assigned])
  end

  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:my_page) do
    Pages::My::Page.new
  end
  let(:assigned_area) { Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)") }
  let(:created_area) { Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(2)") }
  let(:embedded_table) { Pages::EmbeddedWorkPackagesTable.new(assigned_area.area) }
  let(:hierarchies) { Components::WorkPackages::Hierarchies.new }

  current_user { user }

  context "with parent work package" do
    let!(:assigned_work_package_child) do
      create(:work_package,
             subject: "Child",
             parent: assigned_work_package,
             project:,
             type:,
             author: user,
             assigned_to: user)
    end

    it "can toggle hierarchy mode in embedded tables (Regression test #29578)" do
      my_page.visit!

      # exists as default
      assigned_area.expect_to_exist

      page.within(assigned_area.area) do
        # expect hierarchy in child
        hierarchies.expect_mode_enabled

        hierarchies.expect_hierarchy_at assigned_work_package
        hierarchies.expect_leaf_at assigned_work_package_child

        # toggle parent
        hierarchies.toggle_row assigned_work_package
        hierarchies.expect_hierarchy_at assigned_work_package, collapsed: true

        # disable
        hierarchies.disable_via_header
        hierarchies.expect_no_hierarchies

        sleep(0.2)

        # re-enable
        hierarchies.enable_via_header

        sleep(0.2)

        hierarchies.expect_mode_enabled
        hierarchies.expect_hierarchy_at assigned_work_package, collapsed: true
      end
    end
  end

  it "can create a new ticket with correct me values (Regression test #28488)" do
    my_page.visit!

    # exists as default
    assigned_area.expect_to_exist

    expect(assigned_area.area)
      .to have_css(".subject", text: assigned_work_package.subject)

    expect(assigned_area.area)
      .to have_no_css(".subject", text: assigned_to_other_work_package.subject)

    embedded_table.click_inline_create

    subject_field = embedded_table.edit_field(nil, :subject)
    subject_field.expect_active!

    subject_field.set_value "Assigned to me"
    subject_field.save!

    embedded_table.expect_toast(
      message: "Project can't be blank.",
      type: :error
    )

    # Set project
    project_field = embedded_table.edit_field(nil, :project)
    project_field.expect_active!
    project_field.openSelectField
    project_field.set_value project.name

    embedded_table.expect_toast(
      message: "Successful creation. Click here to open this work package in fullscreen view."
    )

    wp = WorkPackage.last
    expect(wp.subject).to eq("Assigned to me")
    expect(wp.assigned_to_id).to eq(user.id)

    embedded_table.expect_work_package_listed wp
  end

  it "can paginate in embedded tables (Regression test #29845)", with_settings: { per_page_options: "1" } do
    my_page.visit!

    # exists as default
    assigned_area.expect_to_exist

    within assigned_area.area do
      expect(page)
        .to have_css(".subject", text: assigned_work_package.subject)
      expect(page)
        .to have_no_css(".subject", text: assigned_work_package_2.subject)

      page.find(".op-pagination--item button", text: "2").click

      expect(page)
        .to have_no_css(".subject", text: assigned_work_package.subject)
      expect(page)
        .to have_css(".subject", text: assigned_work_package_2.subject)
    end

    assigned_area.resize_to(1, 2)

    my_page.expect_toast(message: I18n.t("js.notice_successful_update"))

    assigned_area.expect_to_span(1, 1, 2, 3)
    # has been moved down by resizing
    created_area.expect_to_span(2, 2, 3, 3)
  end
end
