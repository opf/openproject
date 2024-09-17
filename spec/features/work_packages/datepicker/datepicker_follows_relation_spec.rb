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

RSpec.describe "Datepicker logic on follow relationships", :js, :with_cuprite,
               with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:user) { create(:admin) }

  shared_let(:type) { create(:type_bug) }
  shared_let(:milestone_type) { create(:type_milestone) }
  shared_let(:project) { create(:project, types: [milestone_type]) }
  shared_let(:predecessor) do
    create(:work_package,
           type:, project:,
           start_date: Date.parse("2024-02-01"),
           due_date: Date.parse("2024-02-05"))
  end

  let(:work_packages_page) { Pages::FullWorkPackage.new(follower) }
  let(:datepicker) { date_field.datepicker }

  shared_examples "keeps the minimum date from the predecessor when toggling NWD" do
    it "keeps the minimum dates disabled" do
      login_as(user)

      work_packages_page.visit!
      work_packages_page.ensure_page_loaded

      date_field.activate!
      date_field.expect_active!
      # Wait for the datepicker to be initialized
      datepicker.expect_visible

      datepicker.expect_ignore_non_working_days false
      datepicker.expect_scheduling_mode false

      datepicker.show_date "2024-02-05"
      datepicker.expect_disabled Date.parse("2024-02-05")
      datepicker.expect_disabled Date.parse("2024-02-04")
      datepicker.expect_disabled Date.parse("2024-02-03")
      datepicker.expect_disabled Date.parse("2024-02-02")
      datepicker.expect_disabled Date.parse("2024-02-01")

      datepicker.toggle_ignore_non_working_days
      datepicker.expect_ignore_non_working_days true
      datepicker.show_date "2024-02-05"
      datepicker.expect_disabled Date.parse("2024-02-05")
      datepicker.expect_disabled Date.parse("2024-02-04")
      datepicker.expect_disabled Date.parse("2024-02-03")
      datepicker.expect_disabled Date.parse("2024-02-02")
      datepicker.expect_disabled Date.parse("2024-02-01")
    end
  end

  context "if the follower is a task" do
    let!(:follower) { create(:work_package, type:, project:) }
    let!(:relation) { create(:follows_relation, from: follower, to: predecessor) }
    let(:date_field) { work_packages_page.edit_field(:combinedDate) }

    it_behaves_like "keeps the minimum date from the predecessor when toggling NWD"
  end

  context "if the follower is a milestone" do
    let!(:follower) { create(:work_package, type: milestone_type, project:) }
    let!(:relation) { create(:follows_relation, from: follower, to: predecessor) }
    let(:date_field) { work_packages_page.edit_field(:date) }

    it_behaves_like "keeps the minimum date from the predecessor when toggling NWD"
  end
end
