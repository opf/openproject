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

RSpec.describe "Default work package queries", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:user) { create(:admin) }
  current_user { user }

  let(:wp_table) { Pages::WorkPackagesTable.new(project_with_types) }

  describe "Overdue" do
    let!(:work_package) { create(:work_package, subject: "Not overdue", due_date: 5.days.from_now) }
    let!(:due_today_work_package) { create(:work_package, subject: "Not overdue", due_date: Time.zone.today) }
    let!(:overdue_work_package_1_day_ago) { create(:work_package, subject: "Overdue 1 day ago", due_date: 1.day.ago) }
    let!(:overdue_work_package_2_days_ago) { create(:work_package, subject: "Overdue 2 days ago", due_date: 2.days.ago) }
    let!(:closed_status) { create(:closed_status) }
    let!(:closed_work_package) { create(:work_package, subject: "Closed", status: closed_status, due_date: 10.days.ago) }

    it "shows the overdue work package" do
      wp_table.visit!

      wp_table.expect_work_package_listed work_package, due_today_work_package, overdue_work_package_1_day_ago,
                                          overdue_work_package_2_days_ago

      click_link "Overdue", wait: 10

      wp_table.expect_work_package_listed overdue_work_package_1_day_ago, overdue_work_package_2_days_ago
      wp_table.ensure_work_package_not_listed! closed_work_package, work_package, due_today_work_package
    end
  end
end
