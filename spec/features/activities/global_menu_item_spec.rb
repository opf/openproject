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

RSpec.describe "Activities global menu item spec", :js do
  shared_let(:admin) { create(:admin) }

  before do
    project
    login_as admin
    visit root_path
  end

  context "when activity module is active" do
    let(:project) { create(:project, enabled_module_names: %w[activity]) }

    it "does show the menu item" do
      within "#main-menu" do
        click_link "Activity"
      end

      expect(page).to have_current_path(activity_index_path)
    end
  end

  context "when activity module is nowhere active" do
    let(:project) { create(:project, enabled_module_names: %w[]) }

    it "doesn't render the menu item" do
      within "#main-menu" do
        expect(page).to have_no_link "Activity"
      end
    end
  end
end
