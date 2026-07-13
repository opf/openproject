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

RSpec.describe "Meeting index menu",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:public_project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }

  let(:request) do
    get "/projects/#{project.id}/meetings/menu",
        params: { current_href: "/projects/#{project.identifier}/meetings" }
  end

  subject do
    request
    response
  end

  before do
    login_as user
  end

  describe "with normal user that can see meetings" do
    it "shows all meetings and involvements" do
      request

      expect(page).to have_css(".op-submenu--item-action.selected", text: "My meetings")
      expect(page).to have_text "All meetings"
      expect(page).to have_text "Involvement"
      expect(page).to have_text "Created by me"
      expect(page).to have_text "Attended"
    end
  end

  describe "with anonymous user that can see meetings" do
    let(:user) do
      create(:anonymous_role, permissions: %i[view_project view_meetings])
      User.anonymous
    end

    context "when login required", with_settings: { login_required: true } do
      it "redirects to login" do
        expect(subject).to redirect_to(signin_path(back_url: menu_project_meetings_url(project.id)))
      end
    end

    context "when login not required", with_settings: { login_required: false } do
      it "shows all meetings, but no involvements" do
        request

        expect(page).to have_css(".op-submenu--item-action.selected", text: "All meetings")
        expect(page).to have_no_text "My meetings"
        expect(page).to have_no_text "Involvement"
        expect(page).to have_no_text "Created by me"
        expect(page).to have_no_text "Attended"
      end
    end
  end
end
