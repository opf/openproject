# frozen_string_literal: true

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
require_relative "../../support/pages/backlog"

# Regression spec: when a work package is moved to a different container while it is
# open in the split view, the split view still holds the lock_version it fetched on
# opening. Editing then failed with a conflicting-modifications error. The move now
# signals the frontend to refresh the cached work package so editing keeps working.
RSpec.describe "Editing a work package in the split view after moving it",
               :js do
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_sprints manage_sprint_items
                           view_work_packages edit_work_packages]
           })
  end
  let(:backlogs_page) { Pages::Backlog.new(project) }

  let!(:sprint) do
    create(:sprint, project:)
  end
  let!(:target_sprint) do
    create(:sprint, project:)
  end
  let!(:work_package) { create(:work_package, project:, sprint:) }

  current_user { user }

  shared_examples "editing works after the move" do
    it "updates the work package without a conflict error" do
      backlogs_page.visit!

      split_view = backlogs_page.open_work_package_details(work_package)

      move_work_package(target_sprint)

      backlogs_page.expect_no_sprint_items(sprint, items: work_package)
      backlogs_page.expect_sprint_items(target_sprint, items: work_package)
      split_view.expect_attributes sprint: target_sprint

      split_view.edit_field(:subject).update("Updated after move")

      backlogs_page.expect_and_dismiss_toaster(message: "Successful update")
      expect(work_package.reload.subject).to eq("Updated after move")
    end
  end

  context "when moving the work package via the work package menu" do
    def move_work_package(target)
      backlogs_page.click_in_work_package_menu(work_package, "Move to sprint")

      within_modal "Move to sprint" do
        select target.name, from: "Sprint"
        click_on "Move"
      end
    end

    it_behaves_like "editing works after the move"
  end

  context "when moving the work package by dragging it with the mouse", :selenium do
    def move_work_package(target)
      backlogs_page.drag_work_package(work_package, into: target)
    end

    it_behaves_like "editing works after the move"
  end
end
