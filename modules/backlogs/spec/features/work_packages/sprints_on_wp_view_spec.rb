# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Sprint displayed and selectable on work package view", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project) }
  shared_let(:sprint) { create(:sprint, project:, name: "Current sprint") }
  shared_let(:next_sprint) { create(:sprint, project:, name: "Next sprint") }
  shared_let(:completed_sprint) { create(:sprint, project:, status: "completed", name: "Completed sprint") }
  shared_let(:work_package) { create(:work_package, project:, sprint:) }

  let(:permissions) { %i(view_work_packages view_sprints manage_sprint_items) }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  it "shows sprints and allows changing them" do
    wp_page.visit!

    wp_page.expect_attributes sprint: sprint.name

    field = wp_page.work_package_field(:sprint)
    field.activate!

    # Completed sprints are not offered as options
    expect_no_ng_option(field, completed_sprint.name)

    field.autocomplete(next_sprint.name, select: true)

    wp_page.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)

    # Ensure the sprint association is persisted
    wp_page.visit!

    wp_page.expect_attributes sprint: next_sprint.name
  end

  context "when attempting to assign the wp to a bucket" do
    shared_let(:bucket) { create(:backlog_bucket, name: "Bucket", project:) }

    it "clears the sprint (and the other way around) instead of throwing an error" do
      wp_page.visit!

      wp_page.expect_attributes sprint: sprint.name, backlog_bucket: nil

      # Assign to bucket
      field = wp_page.work_package_field(:backlog_bucket)
      field.activate!
      field.autocomplete(bucket.name, select: true)
      wp_page.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)

      # Sprint was unassigned, bucket is assigned
      wp_page.expect_attributes sprint: nil, backlog_bucket: bucket.name
      wp_page.visit!
      wp_page.expect_attributes sprint: nil, backlog_bucket: bucket.name

      # Assign to sprint
      field = wp_page.work_package_field(:sprint)
      field.activate!
      field.autocomplete(sprint.name, select: true)
      wp_page.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)

      # Bucket was unassigned, sprint is assigned
      wp_page.expect_attributes sprint: sprint.name, backlog_bucket: nil
      wp_page.visit!
      wp_page.expect_attributes sprint: sprint.name, backlog_bucket: nil
    end
  end

  context "when lacking the permission to see sprints" do
    let(:permissions) { %i(view_work_packages) }

    it "does not show a sprints property" do
      wp_page.visit!

      wp_page.expect_no_attribute "Sprint"
    end
  end
end
