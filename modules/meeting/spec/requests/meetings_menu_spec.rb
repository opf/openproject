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

  describe "with the past time filter active" do
    let(:meetings_href) { "/projects/#{project.identifier}/meetings" }
    let(:project_filter) { { project_id: { operator: "=", values: [project.id.to_s] } } }
    let(:time_filter) { { time: { operator: "past", values: [] } } }

    context "in the 'All meetings' view" do
      let(:all_past_filter) { [project_filter, time_filter].to_json }
      let(:request) do
        get "/projects/#{project.id}/meetings/menu",
            params: { current_href: meetings_href, filters: all_past_filter }
      end

      it "keeps 'All meetings' selected instead of falling back to 'My meetings'" do
        request

        expect(page).to have_css(".op-submenu--item-action.selected", text: "All meetings")
        expect(page).to have_no_css(".op-submenu--item-action.selected", text: "My meetings")
      end
    end

    context "in the 'Recurring meetings' view" do
      let(:recurring_past_filter) do
        [{ type: { operator: "=", values: ["t"] } }, project_filter, time_filter].to_json
      end
      let(:request) do
        get "/projects/#{project.id}/meetings/menu",
            params: { current_href: meetings_href, filters: recurring_past_filter }
      end

      it "keeps 'Recurring meetings' selected instead of falling back to 'My meetings'" do
        request

        expect(page).to have_css(".op-submenu--item-action.selected", text: "Recurring meetings")
        expect(page).to have_no_css(".op-submenu--item-action.selected", text: "My meetings")
      end
    end
  end

  describe "with a 'part of a meeting series' filter" do
    let(:meetings_href) { "/projects/#{project.identifier}/meetings" }

    context "when set to 'no'" do
      let(:not_recurring_filter) { [{ type: { operator: "=", values: ["f"] } }].to_json }
      let(:request) do
        get "/projects/#{project.id}/meetings/menu",
            params: { current_href: meetings_href, filters: not_recurring_filter }
      end

      it "does not select the 'Recurring meetings' option" do
        request

        expect(page).to have_no_css(".op-submenu--item-action.selected", text: "Recurring meetings")
      end
    end

    context "when added on top of the 'My meetings' filter" do
      let(:my_recurring_filter) do
        [
          { invited_user_id: { operator: "=", values: [user.id.to_s] } },
          { type: { operator: "=", values: ["t"] } }
        ].to_json
      end
      let(:request) do
        get "/projects/#{project.id}/meetings/menu",
            params: { current_href: meetings_href, filters: my_recurring_filter }
      end

      # No single preset matches the combined filters, so nothing is selected
      it "selects neither 'My meetings' nor 'Recurring meetings'" do
        request

        expect(page).to have_no_css(".op-submenu--item-action.selected", text: "My meetings")
        expect(page).to have_no_css(".op-submenu--item-action.selected", text: "Recurring meetings")
      end
    end
  end

  describe "with the 'My meetings' filter" do
    let(:meetings_href) { "/projects/#{project.identifier}/meetings" }

    context "when it is the sole filter" do
      let(:my_filter) { [{ invited_user_id: { operator: "=", values: [user.id.to_s] } }].to_json }
      let(:request) do
        get "/projects/#{project.id}/meetings/menu",
            params: { current_href: meetings_href, filters: my_filter }
      end

      it "selects 'My meetings'" do
        request

        expect(page).to have_css(".op-submenu--item-action.selected", text: "My meetings")
      end
    end
  end
end
