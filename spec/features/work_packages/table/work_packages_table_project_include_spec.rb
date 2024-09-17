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
require_relative "../project_include/project_include_shared_examples"

RSpec.describe "Work package project include", :js do
  shared_let(:enabled_modules) { %w[work_package_tracking] }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:permissions) { %i[view_work_packages edit_work_packages add_work_packages save_queries manage_public_queries] }

  it_behaves_like "has a project include dropdown" do
    shared_let(:work_package_view) { Pages::WorkPackagesTable.new(project) }

    it "correctly filters work packages by project" do
      dropdown.expect_count 1

      # Make sure the filter gets set once
      dropdown.toggle!
      dropdown.expect_open
      dropdown.click_button "Apply"
      dropdown.expect_closed

      work_package_view.expect_work_package_listed(task, other_task, sub_bug, sub_sub_bug)
      work_package_view.ensure_work_package_not_listed!(other_other_task)

      dropdown.toggle!
      dropdown.toggle_checkbox(sub_sub_sub_project.id)
      dropdown.click_button "Apply"
      dropdown.expect_count 1

      work_package_view.expect_work_package_listed(task, other_task, sub_sub_bug, sub_bug)
      work_package_view.ensure_work_package_not_listed!(other_other_task)

      dropdown.toggle!
      dropdown.toggle_checkbox(other_project.id)
      dropdown.click_button "Apply"
      dropdown.expect_count 2

      work_package_view.expect_work_package_listed(task, other_task, sub_sub_bug, sub_bug, other_other_task)

      page.refresh

      work_package_view.expect_work_package_listed(task, other_task, sub_bug, sub_sub_bug, other_other_task)
    end

    it "creates new work packages in the host project of the work package view (regression #42271)" do
      dropdown.expect_count 1

      # Make sure the filter gets set once
      dropdown.toggle!
      dropdown.expect_open
      dropdown.toggle_checkbox(other_sub_sub_project.id)
      dropdown.click_button "Apply"
      dropdown.expect_count 2

      work_package_view.click_inline_create
      subject_field = work_package_view.edit_field(nil, :subject)
      subject_field.expect_active!

      # Save the WP
      subject_field.set_value "Foobar!"
      subject_field.submit_by_enter

      work_package_view.expect_and_dismiss_toaster(
        message: "Successful creation. Click here to open this work package in fullscreen view."
      )

      work_package_view.expect_work_package_subject "Foobar!"

      inline_created = WorkPackage.last
      expect(inline_created.project).to eq(project)
    end
  end
end
