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

RSpec.describe "Backlog bucket displayed and selectable on work package view", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:backlog_bucket) { create(:backlog_bucket, project:, name: "Current bucket") }
  shared_let(:another_bucket) { create(:backlog_bucket, project:, name: "Another bucket") }
  shared_let(:other_project_bucket) { create(:backlog_bucket, project: other_project, name: "Other project bucket") }
  shared_let(:work_package) { create(:work_package, project:, backlog_bucket:) }

  let(:permissions) { %i(view_work_packages view_sprints manage_sprint_items) }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  it "shows the backlog bucket and allows changing it" do
    wp_page.visit!

    wp_page.expect_attributes backlog_bucket: backlog_bucket.name

    field = wp_page.work_package_field(:backlog_bucket)
    field.activate!

    expect_no_ng_option(field, other_project_bucket.name)

    field.autocomplete(another_bucket.name, select: true)

    wp_page.expect_and_dismiss_toaster message: I18n.t(:notice_successful_update)

    # Ensure the change was persisted:
    wp_page.visit!
    wp_page.expect_attributes backlog_bucket: another_bucket.name
  end

  context "when lacking the permission to see sprints" do
    let(:permissions) { %i(view_work_packages) }

    it "does not show a backlog bucket property" do
      wp_page.visit!

      wp_page.expect_no_attribute "Backlog bucket"
    end
  end
end
