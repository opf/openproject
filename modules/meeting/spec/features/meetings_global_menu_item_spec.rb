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
require_relative "../support/pages/meetings/index"

RSpec.describe "Meetings global menu item",
               :js,
               :with_cuprite do
  shared_let(:user_without_permissions) { create(:user) }
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:meetings_label) { I18n.t(:label_meeting_plural) }

  let(:meetings_page) { Pages::Meetings::Index.new(project: nil) }

  before do
    login_as current_user
  end

  context "as a user with permissions" do
    let(:current_user) { admin }

    before do
      meetings_page.navigate_by_global_menu
    end

    it "navigates to the global meetings index page" do
      expect(page).to have_current_path("/meetings")
    end

    specify '"Upcoming invitations" is the default filter set' do
      within "#main-menu" do
        expect(page).to have_css(".selected", text: I18n.t(:label_upcoming_invitations))
      end
    end
  end

  context "as a user without permissions" do
    let(:current_user) { user_without_permissions }

    before do
      visit root_path
    end

    it "does not render" do
      within "#main-menu" do
        expect(page).to have_no_link(meetings_label)
      end
    end
  end
end
