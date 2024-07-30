# frozen_string_literal: true

# -- copyright
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
# ++
#

require "spec_helper"

RSpec.describe "News global menu item spec", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  shared_let(:user_without_permissions) { create(:user) }
  shared_let(:project) { create(:project) }

  before do
    login_as current_user
    visit root_path
  end

  context "as a user with permissions" do
    let(:current_user) { admin }

    it "navigates to the global news page" do
      within "#main-menu" do
        click_link "News"
      end

      expect(page).to have_current_path(news_index_path)

      within "#main-menu" do
        expect(page).to have_css(".selected", text: "News")
      end
    end
  end

  context "as a user without permissions" do
    let(:current_user) { user_without_permissions }

    it "doesn't render the menu item" do
      within "#main-menu" do
        expect(page).to have_no_link "News"
      end
    end
  end
end
