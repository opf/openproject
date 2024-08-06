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
require "features/work_packages/project_include/project_include_shared_examples"
require_relative "../support/pages/calendar"

RSpec.describe "Calendar project include", :js do
  shared_let(:enabled_modules) { %w[work_package_tracking calendar_view] }
  shared_let(:permissions) do
    %i[view_work_packages view_calendar edit_work_packages add_work_packages save_queries manage_public_queries]
  end

  it_behaves_like "has a project include dropdown" do
    let(:work_package_view) { Pages::Calendar.new project }
    let(:dropdown) { Components::ProjectIncludeComponent.new }

    it "correctly filters work packages by project" do
      dropdown.expect_count 1, wait: 10

      # Make sure the filter gets set once
      dropdown.toggle!
      dropdown.expect_open
      dropdown.click_button "Apply"
      dropdown.expect_closed

      work_package_view.expect_event task
      work_package_view.expect_event sub_bug, present: true
      work_package_view.expect_event sub_sub_bug, present: true
      work_package_view.expect_event other_task
      work_package_view.expect_event other_other_task, present: false

      dropdown.toggle!
      dropdown.toggle_checkbox(sub_sub_sub_project.id)
      dropdown.click_button "Apply"
      dropdown.expect_count 1

      work_package_view.expect_event sub_bug, present: true
      work_package_view.expect_event sub_sub_bug

      dropdown.toggle!
      dropdown.toggle_checkbox(other_project.id)
      dropdown.click_button "Apply"
      dropdown.expect_count 2

      work_package_view.expect_event other_task
      work_package_view.expect_event other_other_task

      page.refresh

      work_package_view.expect_event task
      work_package_view.expect_event sub_bug, present: true
      work_package_view.expect_event sub_sub_bug
      work_package_view.expect_event other_task
      work_package_view.expect_event other_other_task
    end
  end
end
