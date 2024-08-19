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

RSpec.describe "Work package activity", :js, :with_cuprite do
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

  current_user { admin }

  context "when the progress values are changed" do
    before do
      wp_page = Pages::FullWorkPackage.new(parent)
      wp_page.visit!
      wp_page.update_attributes estimatedTime: "100" # rubocop:disable Rails/ActiveRecordAliases
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")
      wp_page.update_attributes remainingTime: "5" # rubocop:disable Rails/ActiveRecordAliases
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")
    end

    it "displays changed attributes in the activity tab", :aggregate_failures do
      within("activity-entry", text: admin.name) do
        expect(page).to have_list_item(text: "% Complete set to 95%")
        expect(page).to have_list_item(text: "Work set to 100h")
        expect(page).to have_list_item(text: "Remaining work set to 5h")
        expect(page).to have_list_item(text: "Total work set to 110h")
        expect(page).to have_list_item(text: "Total remaining work set to 8h")
        expect(page).to have_list_item(text: "Total % complete set to 93%")
      end
    end
  end
end
