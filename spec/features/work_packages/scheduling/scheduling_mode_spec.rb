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
           subject: "wp",
           schedule_manually: false, # because parent of wp_child and follows wp_pre
           start_date: Date.parse("2016-01-01"),
           due_date: Date.parse("2016-01-05"),
           parent: wp_parent)
  end
  let!(:wp_parent) do
    create(:work_package,
           project:,
           subject: "wp_parent",
           schedule_manually: false, # because parent of wp
           start_date: Date.parse("2016-01-01"),
           due_date: Date.parse("2016-01-05"))
  end
  let!(:wp_child) do
    create(:work_package,
           project:,
           subject: "wp_child",
           schedule_manually: false, # because needed to have rescheduling working
           start_date: Date.parse("2016-01-01"),
           due_date: Date.parse("2016-01-05"),
           parent: wp)
  end
  let!(:wp_pre) do
    create(:work_package,
           project:,
           subject: "wp_pre",
           start_date: Date.parse("2015-12-15"),
           due_date: Date.parse("2015-12-31")).tap do |pre|
      create(:follows_relation, from: wp, to: pre)
    end
  end
  let!(:wp_suc) do
    create(:work_package,
           project:,
           subject: "wp_suc",
           schedule_manually: false, # because parent of wp_suc_child and follows wp
           start_date: Date.parse("2016-01-06"),
           due_date: Date.parse("2016-01-10"),
           parent: wp_suc_parent).tap do |suc|
      create(:follows_relation, from: suc, to: wp)
    end
  end
  let!(:wp_suc_parent) do
    create(:work_package,
           project:,
           subject: "wp_suc_parent",
           schedule_manually: false, # because parent of wp_suc
           start_date: Date.parse("2016-01-06"),
           due_date: Date.parse("2016-01-10"))
  end
  let!(:wp_suc_child) do
    create(:work_package,
           project:,
           subject: "wp_suc_child",
           schedule_manually: false, # because needed to have rescheduling working
           start_date: Date.parse("2016-01-06"),
           due_date: Date.parse("2016-01-10"),
           parent: wp_suc)
  end
  let(:work_packages_page) { Pages::SplitWorkPackage.new(wp, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(wp) }
  let(:combined_field) { work_packages_page.edit_field(:combinedDate) }
  # get a simplified table showing dates and durations for easier debugging.
  let(:query) do
    create(:query_with_view_work_packages_table,
           user: current_user,
           project:,
           column_names: ["id", "subject", "start_date", "due_date", "duration"])
  end

  def expect_dates(work_package, start_date, due_date)
    work_package.reload
    expect(work_package.start_date).to eql Date.parse(start_date)
    expect(work_package.due_date).to eql Date.parse(due_date)
  end

  current_user { create(:admin) }

  before do
    work_packages_page.visit_query(query)
    work_packages_page.ensure_page_loaded
  end

  it "can toggle the scheduling mode through the date modal" do
    expect(wp.schedule_manually).to be_falsey

    # Editing the start/due dates of a parent work package is possible if the
    # work package is manually scheduled
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.toggle_scheduling_mode # toggle to manual mode
    combined_field.expect_manual_scheduling_mode
    combined_field.update(%w[2016-01-05 2016-01-10], save: false)
    combined_field.expect_duration 6
    combined_field.save!

    work_packages_page.expect_and_dismiss_toaster message: "Successful update."

    # Switch to activity tab and wait for it to load
    work_packages_page.switch_to_tab(tab: :activity)
    work_packages_page.wait_for_activity_tab

    # Changing the scheduling mode is journalized
    activity_tab.expect_journal_changed_attribute(text: "Scheduling mode set to Manual")
    work_packages_page.switch_to_tab(tab: :overview)
    work_packages_page.expect_tab(:overview)
    wait_for_network_idle

    expect_dates(wp, "2016-01-05", "2016-01-10")
    expect(wp.schedule_manually).to be_truthy

    # is not moved because it wp_pre is an indirect predecessor through its
    # parent wp, so it needs to start right after wp_pre
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
    combined_field.toggle_scheduling_mode # toggle to automatic mode

    wait_for_network_idle

    combined_field.expect_automatic_scheduling_mode

    combined_field.save!

    work_packages_page.expect_and_dismiss_toaster message: "Successful update."

    # wp_child had not been moved in the first place
    expect_dates(wp_child, "2016-01-01", "2016-01-05")

    # wp Moved backward again as the child determines the dates again
    expect_dates(wp, "2016-01-01", "2016-01-05")
    expect(wp.schedule_manually).to be_falsey

    # As the child (wp) now again takes up the same time interval as the
    # grandchild (wp_child), the interval is shortened again.
    expect_dates(wp_parent, "2016-01-01", "2016-01-05")

    # wp_suc_child moves backwards to start as soon as possible after its
    # indirect predecessor (wp) as it is in automatic scheduling mode
    expect_dates(wp_suc_child, "2016-01-06", "2016-01-10")

    # wp_suc moves backwards as well because it follows its child dates (wp_suc_child)
    expect_dates(wp_suc, "2016-01-06", "2016-01-10")

    # wp_suc_parent moves backwards as well because it follows its child dates (wp_suc)
    expect_dates(wp_suc_parent, "2016-01-06", "2016-01-10")

    # Switching back to manual scheduling but this time backward will lead to the work package
    # and all work packages that are dependent to be rescheduled again.
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.toggle_scheduling_mode # toggle to manual mode
    combined_field.expect_manual_scheduling_mode

    wait_for_network_idle
    combined_field.expect_calendar

    # Increasing the duration while at it
    combined_field.update(%w[2015-12-20 2015-12-31], save: false)
    combined_field.expect_duration 12
    combined_field.save!

    work_packages_page.expect_and_dismiss_toaster message: "Successful update."

    expect_dates(wp, "2015-12-20", "2015-12-31")
    expect(wp.schedule_manually).to be_truthy

    # child is not moved because it dates depend on its indirect predecessor,
    # wp_pred, rather than on its parent, wp.
    expect_dates(wp_child, "2016-01-01", "2016-01-05")

    # wp_parent start date is moved backwards because its child (wp) was moved
    # backwards but the due date remains unchanged as its grandchild (wp_child)
    # stays put.
    expect_dates(wp_parent, "2015-12-20", "2016-01-05")

    # wp_suc_child moves backwards to start as soon as possible after its
    # indirect predecessor (wp)
    expect_dates(wp_suc_child, "2016-01-01", "2016-01-05")

    # wp_suc moves backwards to follow its child dates (wp_suc_child)
    expect_dates(wp_suc, "2016-01-01", "2016-01-05")

    # wp_suc_parent moves backwards to follow its child dates (wp_suc)
    expect_dates(wp_suc_parent, "2016-01-01", "2016-01-05")

    # Switching back to automatic scheduling will lead to the work package
    # and all work packages that are dependent to be rescheduled again to
    # satisfy wp follows wp_pre relation.
    combined_field.activate!(expect_open: false)
    combined_field.expect_active!
    combined_field.toggle_scheduling_mode
    combined_field.expect_automatic_scheduling_mode

    wait_for_network_idle

    combined_field.save!

    work_packages_page.expect_and_dismiss_toaster message: "Successful update."

    # child Had not been moved in the first place
    expect_dates(wp_child, "2016-01-01", "2016-01-05")

    # wp Moved forward again as the child determines the dates again
    expect_dates(wp, "2016-01-01", "2016-01-05")
    expect(wp.schedule_manually).to be_falsey

    # As the child (wp) now again takes up the same time interval as the
    # grandchild (wp_child), the interval is shortened again.
    expect_dates(wp_parent, "2016-01-01", "2016-01-05")

    # wp_suc_child moves forward to start right after its indirect predecessor (wp)
    expect_dates(wp_suc_child, "2016-01-06", "2016-01-10")

    # wp_suc moves forwards to follow its child dates (wp_suc_child)
    expect_dates(wp_suc, "2016-01-06", "2016-01-10")

    # wp_suc_parent moves forwards to follow its child dates (wp_suc)
    expect_dates(wp_suc_parent, "2016-01-06", "2016-01-10")
  end
end
