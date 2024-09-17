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
require "features/page_objects/notification"
require "features/work_packages/details/inplace_editor/shared_examples"
require "features/work_packages/shared_contexts"
require "support/edit_fields/edit_field"
require "features/work_packages/work_packages_page"

RSpec.describe "scheduling mode", :js do
  let(:project) { create(:project_with_types, public: true) }
  # Constructing a work package graph that looks like this:
  #
  #                   wp_parent       wp_suc_parent
  #                       |                |
  #                     hierarchy       hierarchy
  #                       |                |
  #                       v                v
  # wp_pre <- follows <- wp <- follows - wp_suc
  #                       |                |
  #                    hierarchy        hierarchy
  #                       |               |
  #                       v               v
  #                     wp_child      wp_suc_child
  #
  let!(:wp) do
    create(:work_package,
           project:,
           start_date: Date.parse("2016-01-01"),
           due_date: Date.parse("2016-01-05"),
           parent: wp_parent)
  end
  let!(:wp_parent) do
    create(:work_package,
           project:,
           start_date: Date.parse("2016-01-01"),
           due_date: Date.parse("2016-01-05"))
  end
  let!(:wp_child) do
    create(:work_package,
           project:,
           start_date: Date.parse("2016-01-01"),
           due_date: Date.parse("2016-01-05"),
           parent: wp)
  end
  let!(:wp_pre) do
    create(:work_package,
           project:,
           start_date: Date.parse("2015-12-15"),
           due_date: Date.parse("2015-12-31")).tap do |pre|
      create(:follows_relation, from: wp, to: pre)
    end
  end
  let!(:wp_suc) do
    create(:work_package,
           project:,
           start_date: Date.parse("2016-01-06"),
           due_date: Date.parse("2016-01-10"),
           parent: wp_suc_parent).tap do |suc|
      create(:follows_relation, from: suc, to: wp)
    end
  end
  let!(:wp_suc_parent) do
    create(:work_package,
           project:,
           start_date: Date.parse("2016-01-06"),
           due_date: Date.parse("2016-01-10"))
  end
  let!(:wp_suc_child) do
    create(:work_package,
           project:,
           start_date: Date.parse("2016-01-06"),
           due_date: Date.parse("2016-01-10"),
           parent: wp_suc)
  end
  let(:work_packages_page) { Pages::SplitWorkPackage.new(wp, project) }

  let(:combined_field) { work_packages_page.edit_field(:combinedDate) }

  def expect_dates(work_package, start_date, due_date)
    work_package.reload
    expect(work_package.start_date).to eql Date.parse(start_date)
    expect(work_package.due_date).to eql Date.parse(due_date)
  end

  current_user { create(:admin) }

  before do
    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  it "can toggle the scheduling mode through the date modal" do
    expect(wp.schedule_manually).to be_falsey

    # Editing the start/due dates of a parent work package is possible if the
    # work package is manually scheduled
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.toggle_scheduling_mode
    combined_field.update(%w[2016-01-05 2016-01-10], save: false)
    combined_field.expect_duration 6
    combined_field.save!

    work_packages_page.expect_and_dismiss_toaster message: "Successful update."

    # Changing the scheduling mode is journalized
    work_packages_page.expect_activity_message("Manual scheduling activated")

    expect_dates(wp, "2016-01-05", "2016-01-10")
    expect(wp.schedule_manually).to be_truthy

    # is not moved because it is a child
    expect_dates(wp_child, "2016-01-01", "2016-01-05")

    # The due date is moved backwards because its child was moved
    # but the start date remains unchanged as its grandchild stays put.
    expect_dates(wp_parent, "2016-01-01", "2016-01-10")

    # is moved forward because of the follows relationship
    expect_dates(wp_suc, "2016-01-11", "2016-01-15")

    # is moved forward because it is the parent of the successor
    expect_dates(wp_suc_parent, "2016-01-11", "2016-01-15")

    # is moved forward as the whole hierarchy is moved forward
    expect_dates(wp_suc_child, "2016-01-11", "2016-01-15")

    # Switching back to automatic scheduling will lead to the work package
    # and all work packages that are dependent to be rescheduled again.
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.toggle_scheduling_mode
    combined_field.save!

    work_packages_page.expect_and_dismiss_toaster message: "Successful update."

    # Moved backward again as the child determines the dates again
    expect_dates(wp, "2016-01-01", "2016-01-05")
    expect(wp.schedule_manually).to be_falsey

    # Had not been moved in the first place
    expect_dates(wp_child, "2016-01-01", "2016-01-05")

    # As the child now again takes up the same time interval as the grandchild,
    # the interval is shortened again.
    expect_dates(wp_parent, "2016-01-01", "2016-01-05")

    # does not move backwards, as it just increases the gap between wp and wp_suc
    expect_dates(wp_suc, "2016-01-11", "2016-01-15")

    # does not move backwards either
    expect_dates(wp_suc_parent, "2016-01-11", "2016-01-15")

    # does not move backwards either because its parent did not move
    expect_dates(wp_suc_child, "2016-01-11", "2016-01-15")

    # Switching back to manual scheduling but this time backward will lead to the work package
    # and all work packages that are dependent to be rescheduled again.
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.toggle_scheduling_mode

    # The calendar needs some time to get initialized.
    sleep 2
    combined_field.expect_calendar

    # Increasing the duration while at it
    combined_field.update(%w[2015-12-20 2015-12-31], save: false)
    combined_field.expect_duration 12
    combined_field.save!

    work_packages_page.expect_and_dismiss_toaster message: "Successful update."

    expect_dates(wp, "2015-12-20", "2015-12-31")
    expect(wp.schedule_manually).to be_truthy

    # is not moved because it is a child
    expect_dates(wp_child, "2016-01-01", "2016-01-05")

    # The start date is moved forward because its child was moved
    # but the due date remains unchanged as its grandchild stays put.
    expect_dates(wp_parent, "2015-12-20", "2016-01-05")

    # does not move backwards, as it just increases the gap between wp and wp_suc
    expect_dates(wp_suc, "2016-01-11", "2016-01-15")

    # does not move backwards either
    expect_dates(wp_suc_parent, "2016-01-11", "2016-01-15")

    # does not move backwards either because its parent did not move
    expect_dates(wp_suc_child, "2016-01-11", "2016-01-15")

    # Switching back to automatic scheduling will lead to the work package
    # and all work packages that are dependent to be rescheduled again to
    # satisfy wp follows wp_pre relation.
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.toggle_scheduling_mode
    combined_field.save!

    work_packages_page.expect_and_dismiss_toaster message: "Successful update."

    # Moved backwards again as the child determines the dates again
    expect_dates(wp, "2016-01-01", "2016-01-05")
    expect(wp.schedule_manually).to be_falsey

    # Had not been moved in the first place
    expect_dates(wp_child, "2016-01-01", "2016-01-05")

    # As the child now again takes up the same time interval as the grandchild,
    # the interval is shortened again.
    expect_dates(wp_parent, "2016-01-01", "2016-01-05")

    # does not move
    expect_dates(wp_suc, "2016-01-11", "2016-01-15")

    # does not move either
    expect_dates(wp_suc_parent, "2016-01-11", "2016-01-15")

    # does not move either because its parent did not move
    expect_dates(wp_suc_child, "2016-01-11", "2016-01-15")
  end
end
