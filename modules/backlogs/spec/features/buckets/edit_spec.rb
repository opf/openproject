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

RSpec.describe "Backlog bucket renaming", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking backlogs])
  end
  shared_let(:bucket) { create(:backlog_bucket, project:, name: "Draft bucket") }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user,
           member_with_permissions: {
             project => %i[view_sprints view_work_packages create_sprints]
           })
  end

  it "renames a backlog bucket via the menu" do
    backlogs_page.visit!
    backlogs_page.expect_bucket_names_in_order("Draft bucket")

    backlogs_page.click_in_backlog_bucket_menu(bucket, "Edit backlog bucket")

    within_dialog "Edit backlog bucket" do
      expect(page).to have_field "Name", with: "Draft bucket"
      fill_in "Name", with: "Polished bucket"
      click_on "Save"
    end

    expect_and_dismiss_flash type: :success, exact_message: "Successful update."
    backlogs_page.expect_bucket_names_in_order("Polished bucket")
    expect(bucket.reload.name).to eq "Polished bucket"
  end

  it "validates that the name is present when saving" do
    backlogs_page.visit!

    backlogs_page.click_in_backlog_bucket_menu(bucket, "Edit backlog bucket")

    within_dialog "Edit backlog bucket" do
      fill_in "Name", with: ""
      click_on "Save"

      expect(page).to have_field "Name", validation_error: "can't be blank"
    end

    expect(bucket.reload.name).to eq "Draft bucket"
  end

  context "without the :create_sprints permission" do
    current_user do
      create(:user,
             member_with_permissions: {
               project => %i[view_sprints view_work_packages]
             })
    end

    it "does not expose the bucket actions menu" do
      backlogs_page.visit!

      backlogs_page.expect_no_backlog_bucket_menu(bucket)
    end
  end
end
