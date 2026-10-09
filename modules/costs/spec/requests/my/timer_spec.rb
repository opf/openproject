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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../spec_helper"

RSpec.describe "My timer", type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:, subject: "Plan the conference") }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages log_own_time] })
  end

  current_user { user }

  describe "GET /my/timer" do
    it "renders the menu frame for the running timer" do
      timer = create(:time_entry, user:, entity: work_package, project:, ongoing: true, hours: nil)

      get my_timers_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<turbo-frame id="my_timers">')
      expect(response.body).to include("data-ongoing-timer")
      expect(response.body).to include("/time_entries/#{timer.id}/dialog")
    end

    it "renders an empty frame without a running timer" do
      get my_timers_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<turbo-frame id="my_timers">')
      expect(response.body).not_to include("data-ongoing-timer")
    end

    it "ignores running timers of other users" do
      other_user = create(:user, member_with_permissions: { project => %i[view_work_packages log_own_time] })
      create(:time_entry, user: other_user, entity: work_package, project:, ongoing: true, hours: nil)

      get my_timers_path

      expect(response.body).not_to include("data-ongoing-timer")
    end

    context "when not logged in" do
      current_user { User.anonymous }

      it "requires a login" do
        get my_timers_path

        expect(response).to redirect_to(signin_path(back_url: my_timers_url))
      end
    end
  end

  describe "the user menu" do
    it "renders the timer frame inline so no request is needed to show it" do
      create(:time_entry, user:, entity: work_package, project:, ongoing: true, hours: nil)

      get my_page_path

      frame = response.parsed_body.at_css("turbo-frame#my_timers")
      expect(frame["src"]).to be_nil
      expect(frame["target"]).to eq("_top")
      expect(frame["data-reload-frame-on-event-event-name-value"]).to eq(My::Timer::MenuSectionComponent::CHANGED_EVENT)
      expect(frame.at_css("[data-ongoing-timer]")).to be_present
    end
  end
end
