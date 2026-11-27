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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "categories inplace editor", :js,
               with_flag: { work_package_multiple_categories: true },
               with_settings: { work_package_multiple_categories: true } do
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end
  let!(:category_one) { create(:category, project:, name: "Backend") }
  let!(:category_two) { create(:category, project:, name: "Design") }
  let!(:work_package) do
    create(:work_package, project:).tap do |wp|
      wp.category_ids_replacements = [category_one.id]
      wp.save!
    end
  end
  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }

  before do
    login_as(user)
  end

  it "adds a category to the work package from the full view" do
    work_package_page.visit!
    work_package_page.ensure_page_loaded

    field = work_package_page.work_package_field(:categories)
    field.expect_state_text category_one.name

    field.activate!
    field.set_value category_two.name
    field.submit_by_dashboard

    work_package_page.expect_and_dismiss_toaster(message: "Successful update.")

    expect(work_package.reload.categories).to contain_exactly(category_one, category_two)
  end
end
