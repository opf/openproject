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

RSpec.describe "mobile date filter work packages", :js, :with_cuprite do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  shared_let(:wp_cards) { Pages::WorkPackageCards.new(project) }
  shared_let(:filters) { Components::WorkPackages::Filters.new }
  shared_let(:work_package_with_due_date) { create(:work_package, project:, due_date: Date.current) }
  shared_let(:work_package_without_due_date) { create(:work_package, project:, due_date: 5.days.from_now) }

  current_user { user }

  include_context "with mobile screen size"

  before do
    wp_table.visit!
  end

  context "when filtering between finish date" do
    it "allows filtering, saving and retrieving and altering the saved filter" do
      filters.open
      filters.add_filter("Finish date")
      filters.set_operator("Finish date", "between", "dueDate")

      start_field = find_test_selector("op-basic-range-date-picker-start")
      end_field = find_test_selector("op-basic-range-date-picker-end")

      clear_input_field_contents(start_field)
      clear_input_field_contents(end_field)

      start_field.set 1.day.ago.to_date
      start_field.send_keys :tab
      end_field.set Date.current
      end_field.send_keys :tab

      wait_for_reload
      loading_indicator_saveguard

      wp_cards.expect_work_package_count 1
      wp_cards.expect_work_package_listed work_package_with_due_date
      wp_cards.expect_work_package_not_listed work_package_without_due_date

      wp_table.save_as("Some query name")
      wp_table.expect_and_dismiss_toaster(message: "Successful creation.")

      last_query = Query.last
      date_filter = last_query.filters.last
      expect(date_filter.values).to eq [1.day.ago.to_date.iso8601, Date.current.iso8601]
    end
  end

  context "when filtering on finish date" do
    it "allows filtering, saving and retrieving and altering the saved filter" do
      filters.open
      filters.add_filter("Finish date")
      filters.set_operator("Finish date", "on", "dueDate")

      date_field = find_field "values-dueDate"
      expect(date_field["type"]).to eq "date"

      clear_input_field_contents(date_field)
      date_field.set Date.current

      wait_for_reload
      loading_indicator_saveguard

      wp_cards.expect_work_package_count 1
      wp_cards.expect_work_package_listed work_package_with_due_date
      wp_cards.expect_work_package_not_listed work_package_without_due_date

      wp_table.save_as("Some query name")
      wp_table.expect_and_dismiss_toaster(message: "Successful creation.")

      last_query = Query.last
      date_filter = last_query.filters.last
      expect(date_filter.values).to eq [Date.current.iso8601]
    end
  end
end
