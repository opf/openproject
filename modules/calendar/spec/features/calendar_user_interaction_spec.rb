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
require_relative "shared_context"

RSpec.describe "Calendar drag&dop and resizing", :js do
  include_context "with calendar full access"

  let!(:other_user) do
    create(:user,
           firstname: "Bernd",
           member_with_permissions: { project => %w[view_work_packages view_calendar] })
  end

  let!(:work_package) do
    create(:work_package,
           project:,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday))
  end

  before do
    login_as current_user
    calendar.visit!
    calendar.expect_event work_package
  end

  context "with full permissions" do
    it "allows to resize to change the dates of a wp" do
      target = work_package.due_date + 1.day
      current_start = work_package.start_date
      retry_block do
        calendar.resize_date(work_package, target)
      end

      calendar.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      work_package.reload
      expect(work_package.due_date).to eq target
      expect(work_package.start_date).to eq current_start
    end

    it "allows to resize from the start" do
      target = work_package.start_date - 1.day
      current_end = work_package.due_date

      retry_block do
        calendar.resize_date(work_package, target, end_date: false)
      end

      calendar.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      work_package.reload
      expect(work_package.start_date).to eq target
      expect(work_package.due_date).to eq current_end
    end

    it "allows to drag the work package to another date" do
      target = Time.zone.today.beginning_of_week

      retry_block do
        calendar.drag_event(work_package, target)
      end

      calendar.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      work_package.reload

      # The date is being dragged in the middle section
      expect(work_package.start_date).to eq(target - 1.day)
      expect(work_package.due_date).to eq(target + 1.day)
    end
  end

  context "without permission to edit" do
    let(:current_user) { other_user }

    it "allows neither dragging nor resizing any wp" do
      calendar.expect_event work_package
      calendar.expect_wp_not_resizable(work_package)
      calendar.expect_wp_not_draggable(work_package)
    end
  end
end
