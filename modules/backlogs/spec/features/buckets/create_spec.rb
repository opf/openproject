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

RSpec.describe "Backlog bucket creation", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking backlogs])
  end

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user,
           member_with_permissions: {
             project => %i[view_sprints view_work_packages create_sprints]
           })
  end

  it "creates a new backlog bucket via the dialog" do
    backlogs_page.visit!
    backlogs_page.open_create_bucket_dialog

    within_dialog "New backlog bucket" do
      fill_in "Name", with: "Discovery work"
      click_on "Create"
    end

    expect_and_dismiss_flash type: :success, exact_message: "Successful creation."
    backlogs_page.expect_bucket_names_in_order("Discovery work")

    bucket = BacklogBucket.find_by!(project:, name: "Discovery work")
    expect(bucket.work_packages).to be_empty
  end

  it "validates that the name is present" do
    backlogs_page.visit!

    backlogs_page.open_create_bucket_dialog

    within_dialog "New backlog bucket" do
      fill_in "Name", with: ""
      click_on "Create"

      expect(page).to have_field "Name", validation_error: "can't be blank"
    end

    expect(BacklogBucket.where(project:)).to be_empty
  end

  context "without the :create_sprints permission" do
    current_user do
      create(:user,
             member_with_permissions: {
               project => %i[view_sprints view_work_packages]
             })
    end

    it "does not show the create button" do
      backlogs_page.visit!

      backlogs_page.expect_no_new_backlog_bucket_button
    end
  end
end
