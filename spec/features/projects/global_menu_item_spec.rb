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

RSpec.describe "Projects global menu item", :js, :with_cuprite do
  shared_let(:user) { create(:user) }
  shared_let(:admin) { create(:admin) }

  current_user { user }

  before do
    visit root_path
  end

  it "navigates to the projects#index page" do
    within "#main-menu" do
      click_link text: "Projects"
    end

    expect(page).to have_current_path(projects_path)
  end

  context "when navigated to the projects#index page" do
    before do
      within "#main-menu" do
        click_link text: "Projects"
      end
    end

    it "renders the preset filters" do
      within "#main-menu" do
        expect(page).to have_link text: I18n.t("projects.lists.active")
        expect(page).to have_link text: I18n.t("projects.lists.my")
        expect(page).to have_link text: I18n.t("activerecord.attributes.project.status_codes.on_track")
        expect(page).to have_link text: I18n.t("activerecord.attributes.project.status_codes.off_track")
        expect(page).to have_link text: I18n.t("activerecord.attributes.project.status_codes.at_risk")
      end
    end

    context "with an admin user" do
      current_user { admin }

      it "renders the archived filter as well" do
        within "#main-menu" do
          expect(page).to have_link text: I18n.t("projects.lists.active")
          expect(page).to have_link text: I18n.t("projects.lists.my")
          expect(page).to have_link text: I18n.t("projects.lists.archived")
          expect(page).to have_link text: I18n.t("activerecord.attributes.project.status_codes.on_track")
          expect(page).to have_link text: I18n.t("activerecord.attributes.project.status_codes.off_track")
          expect(page).to have_link text: I18n.t("activerecord.attributes.project.status_codes.at_risk")
        end
      end
    end
  end
end
