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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "What's new menu", :js do
  let(:user) { create(:user) }
  let(:version) { "#{OpenProject::VERSION::MAJOR}.#{OpenProject::VERSION::MINOR}" }

  before do
    login_as user
  end

  context "with the feature flag active", with_flag: { whats_new_menu: true } do
    it "lazy loads the content when the menu opens" do
      visit home_path

      expect(page).to have_no_test_selector("op-header-whats-new-content", visible: :all)

      find_test_selector("op-header-whats-new-button").click

      within_test_selector("op-header-whats-new-content") do
        expect(page).to have_heading("What's new in #{version}")
      end
    end

    context "on mobile" do
      include_context "with mobile screen size"

      it "hides the button" do
        visit home_path

        expect(page).to have_test_selector("header-help-button")
        expect(page).to have_no_test_selector("op-header-whats-new-button")
      end
    end
  end

  context "with the feature flag inactive", with_flag: { whats_new_menu: false } do
    it "does not show the button" do
      visit home_path

      expect(page).to have_test_selector("header-help-button")
      expect(page).to have_no_test_selector("op-header-whats-new-button", visible: :all)
    end
  end
end
