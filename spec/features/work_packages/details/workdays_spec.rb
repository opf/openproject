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

RSpec.describe "Work packages datepicker workdays", :js, with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:project) { create(:project_with_types, public: true) }
  shared_let(:work_package) { create(:work_package, project:, start_date: Date.parse("2022-01-01")) }
  shared_let(:user) { create(:admin) }
  shared_let(:work_packages_page) { Pages::FullWorkPackage.new(work_package, project) }

  let(:combined_date) { work_packages_page.edit_field(:combinedDate) }

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded

    combined_date.activate!
    combined_date.expect_active!
  end

  context "with default work days" do
    shared_let(:working_days) { week_with_saturday_and_sunday_as_weekend }

    it "shows them as disabled" do
      expect(page).to have_css(".dayContainer", count: 2)

      weekend_days = %w[1 2 8 9 15 16 22 23 29 30].map(&:to_i)
      weekend_days.each do |weekend_day|
        expect(page).to have_css(".dayContainer:first-of-type .flatpickr-day.flatpickr-non-working-day",
                                 text: weekend_day,
                                 exact_text: true)
      end

      ((1..31).to_a - weekend_days).each do |workday|
        expect(page).to have_css(".dayContainer:first-of-type .flatpickr-day:not(.flatpickr-non-working-day)",
                                 text: workday,
                                 exact_text: true)
      end
    end
  end
end
