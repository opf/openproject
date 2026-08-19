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

RSpec.describe "Work package activity", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  before_all do
    set_factory_default(:user, admin)
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
  end

  let_work_packages(<<~TABLE)
    hierarchy    | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
    parent       |      |                |            |        |                  |
      child      |  10h |             3h |        70% |    10h |               3h |          70%
  TABLE

  let(:parent_page) { Pages::FullWorkPackage.new(parent) }
  let(:popover) { Components::WorkPackages::ProgressPopover.new }
  let(:activity_tab) { Components::WorkPackages::Activities.new(parent) }

  current_user { admin }

  context "when the progress values are changed" do
    before do
      # set WORK_PACKAGES_ACTIVITIES_TAB_POLLING_INTERVAL_IN_MS from 10s to 1s
      # to speed up the polling interval for test duration
      # TODO: Redefine interval as a setting?
      ENV["WORK_PACKAGES_ACTIVITIES_TAB_POLLING_INTERVAL_IN_MS"] = "1000"

      parent_page.visit!
      popover.open
      popover.set_values(work: "100", remaining_time: "5")
      popover.save
      parent_page.expect_and_dismiss_toaster(message: "Successful update.")
      parent_page.wait_for_activity_tab
    end

    after do
      ENV.delete("WORK_PACKAGES_ACTIVITIES_TAB_POLLING_INTERVAL_IN_MS")
    end

    it "displays changed attributes in the activity tab" do
      activity_tab.expect_journal_changed_attribute(text: "% Complete set to 95%")
      activity_tab.expect_journal_changed_attribute(text: "Work set to 100h")
      activity_tab.expect_journal_changed_attribute(text: "Remaining work set to 5h")
      activity_tab.expect_journal_changed_attribute(text: "Total work set to 110h")
      activity_tab.expect_journal_changed_attribute(text: "Total remaining work set to 8h")
      activity_tab.expect_journal_changed_attribute(text: "Total % complete set to 93%")
    end
  end
end
