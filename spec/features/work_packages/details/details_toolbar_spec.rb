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
require "features/work_packages/work_packages_page"

RSpec.describe "Work package details toolbar", :js do
  include_context "with axe on Cuprite"

  let(:project) { create(:project_with_types, public: true) }
  let!(:work_package) { create(:work_package, project:) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  describe "toggle watch state" do
    let(:user) { create(:admin) }

    before do
      login_as(user)
      work_packages_page.visit_index(work_package)
    end

    it "toggles the watch state" do
      expect(work_package.watcher_users).not_to include(user)

      within ".work-packages--details-toolbar" do
        click_on accessible_name: "Watch work package"
        expect(page).to have_button(accessible_name: "Unwatch work package")
        expect(work_package.reload.watcher_users).to include(user)

        click_on accessible_name: "Unwatch work package"
        expect(page).to have_button(accessible_name: "Watch work package")
        expect(work_package.reload.watcher_users).not_to include(user)

        click_on accessible_name: "Watch work package"
        expect(page).to have_button(accessible_name: "Unwatch work package")
      end

      expect(work_package.reload.watcher_users).to include(user)
      expect(page).to be_axe_clean.within(".work-packages--details-toolbar")
    end
  end
end
