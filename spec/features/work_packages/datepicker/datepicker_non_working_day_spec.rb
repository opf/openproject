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
require "support/edit_fields/edit_field"

RSpec.describe "Datepicker modal individual non working days (WP #44453)", :js,
               with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }

  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:type_milestone) { create(:type_milestone) }
  shared_let(:project) { create(:project, types: [type_bug, type_milestone]) }

  shared_let(:bug_wp) { create(:work_package, project:, type: type_bug, ignore_non_working_days: false) }
  shared_let(:milestone_wp) { create(:work_package, project:, type: type_milestone, ignore_non_working_days: false) }

  shared_let(:non_working_day_this_week) do
    create(:non_working_day,
           date: Time.zone.today.beginning_of_week.next_occurring(:tuesday))
  end

  shared_let(:non_working_day_next_year) do
    create(:non_working_day,
           date: Time.zone.today.end_of_year.next_occurring(:tuesday))
  end

  shared_examples "shows individual non working days" do
    let(:work_packages_page) { Pages::FullWorkPackage.new(work_package, project) }
    let(:date_field) { work_packages_page.edit_field(date_attribute) }
    let(:datepicker) { date_field.datepicker }

    it "loads and shows individual non working days when navigating" do
      login_as user

      work_packages_page.visit!
      work_packages_page.ensure_page_loaded

      date_field.activate!
      date_field.expect_active!
      # Wait for the datepicker to be initialized
      datepicker.expect_visible

      datepicker.show_date non_working_day_this_week.date
      datepicker.expect_non_working non_working_day_this_week.date

      datepicker.show_date non_working_day_next_year.date

      datepicker.expect_non_working non_working_day_next_year.date
    end
  end

  context "for multi date work package" do
    let(:work_package) { bug_wp }
    let(:date_attribute) { :combinedDate }

    it_behaves_like "shows individual non working days"
  end

  context "for milestone work package" do
    let(:work_package) { milestone_wp }
    let(:date_attribute) { :date }

    it_behaves_like "shows individual non working days"
  end
end
