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

RSpec.describe "Cost and Reports Main Menu Item", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:user_with_permissions) { create(:user, member_with_permissions: { project => %i[view_time_entries] }) }
  shared_let(:user_without_permissions) { create(:user) }

  before do
    login_as current_user
    visit root_path
  end

  shared_examples "visiting the global cost reports page" do
    it "allows visiting the global cost reports page" do
      within "#main-menu" do
        click_link I18n.t(:cost_reports_title)
      end

      expect(page).to have_current_path(url_for(controller: "/cost_reports",
                                                action: "index",
                                                project_id: nil,
                                                only_path: true))
    end
  end

  describe "Main Menu" do
    context "as an admin" do
      let(:current_user) { admin }

      include_examples "visiting the global cost reports page"
    end

    context "as a user with permissions" do
      let(:current_user) { user_with_permissions }

      include_examples "visiting the global cost reports page"
    end

    context "as a user without adequate permissions" do
      let(:current_user) { user_without_permissions }

      it "is not rendered" do
        within "#main-menu" do
          expect(page).to have_no_link(I18n.t(:cost_reports_title))
        end
      end
    end
  end
end
