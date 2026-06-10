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

RSpec.describe "Meeting index",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }

  shared_let(:past) do
    create(:meeting,
           :author_participates,
           title: "an earlier meeting",
           start_time: DateTime.parse("2025-01-29T06:00:00Z"),
           project:,
           author: user)
  end

  shared_let(:today) do
    create(:meeting,
           :author_participates,
           title: "meeting starting soon",
           start_time: DateTime.parse("2025-01-29T10:00:00Z"),
           project:,
           author: user)
  end

  shared_let(:tonight) do
    create(:meeting,
           :author_participates,
           title: "meeting starting tonight",
           start_time: DateTime.parse("2025-01-29T22:00:00Z"),
           project:,
           author: user)
  end

  shared_let(:tomorrow) do
    create(:meeting,
           :author_participates,
           title: "meeting starting tomorrow",
           start_time: DateTime.parse("2025-01-30T10:00:00Z"),
           project:,
           author: user)
  end

  shared_let(:saturday) do
    create(:meeting,
           :author_participates,
           title: "weekend meeting on saturday",
           start_time: DateTime.parse("2025-02-01T10:00:00Z"),
           project:,
           author: user)
  end

  shared_let(:sunday) do
    create(:meeting,
           :author_participates,
           title: "weekend meeting on sunday",
           start_time: DateTime.parse("2025-02-02T10:00:00Z"),
           project:,
           author: user)
  end

  shared_let(:next_monday) do
    create(:meeting,
           :author_participates,
           title: "meeting on next monday",
           start_time: DateTime.parse("2025-02-03T10:00:00Z"),
           project:,
           author: user)
  end

  shared_let(:next_friday) do
    create(:meeting,
           :author_participates,
           title: "meeting on next friday",
           start_time: DateTime.parse("2025-02-07T10:00:00Z"),
           project:,
           author: user)
  end

  let(:request) { get "/projects/#{project.id}/meetings" }
  let(:current_time) { "2025-01-29T8:00:00Z".to_datetime }

  subject do
    Timecop.freeze(current_time) do
      request
    end

    response
  end

  before do
    login_as user
  end

  describe "with start_of_week on monday",
           with_settings: { start_of_week: 1 } do
    it "sorts upcoming meetings into buckets" do
      expect(subject).to have_http_status(:ok)
      content = page.find_by_id("content")
      expect(content).to have_text "Tomorrow"
      expect(content).to have_text "Later this week"
      expect(content).to have_text "Next week and later"
      expect(content).to have_no_text "an earlier meeting"

      today = page.find("[data-test-selector='meetings-table-today']")
      expect(today).to have_text "meeting starting soon"
      expect(today).to have_text "meeting starting tonight"

      tomorrow = page.find("[data-test-selector='meetings-table-tomorrow']")
      expect(tomorrow).to have_text "meeting starting tomorrow"

      this_week = page.find("[data-test-selector='meetings-table-this_week']")
      expect(this_week).to have_text "weekend meeting on saturday"
      expect(this_week).to have_text "weekend meeting on sunday"

      later = page.find("[data-test-selector='meetings-table-later']")
      expect(later).to have_text "meeting on next monday"
      expect(later).to have_text "meeting on next friday"
    end

    context "when we request as a user with different time zone" do
      before do
        user.pref.time_zone = "Asia/Tokyo"
        user.save!
      end

      it "shows the meetings in the user's time zone" do
        expect(subject).to have_http_status(:ok)

        content = page.find_by_id("content")
        expect(content).to have_text "Tomorrow"
        expect(content).to have_text "Later this week"
        expect(content).to have_text "Next week and later"
        expect(content).to have_no_text "an earlier meeting"

        today = page.find("[data-test-selector='meetings-table-today']")
        expect(today).to have_text "meeting starting soon"
        expect(today).to have_no_text "meeting starting tonight"

        tomorrow = page.find("[data-test-selector='meetings-table-tomorrow']")
        expect(tomorrow).to have_text "meeting starting tomorrow"
        expect(tomorrow).to have_text "meeting starting tonight"
      end
    end

    context "when we request after 10am" do
      let(:current_time) { "2025-01-29T14:00:00Z".to_datetime }

      it "does not include times for next monday in earlier groups (Regression #61486)" do
        expect(subject).to have_http_status(:ok)
        content = page.find_by_id("content")
        expect(content).to have_text "Tomorrow"
        expect(content).to have_text "Later this week"
        expect(content).to have_text "Next week and later"
        expect(content).to have_no_text "an earlier meeting"

        later = page.find("[data-test-selector='meetings-table-later']")
        expect(later).to have_text "meeting on next monday"
      end
    end

    context "when some meeting groups are empty" do
      before do
        today.destroy!
        tonight.destroy!
      end

      it "shows only the matching bucket" do
        expect(subject).to have_http_status(:ok)
        content = page.find_by_id("content")
        expect(content).to have_text "Tomorrow"
        expect(content).to have_text "Later this week"
        expect(content).to have_text "Next week and later"
        expect(content).to have_no_text "Today"

        expect(page).to have_no_css("#meetings-table-today")

        tomorrow = page.find("[data-test-selector='meetings-table-tomorrow']")
        expect(tomorrow).to have_text "meeting starting tomorrow"

        this_week = page.find("[data-test-selector='meetings-table-this_week']")
        expect(this_week).to have_text "weekend meeting on saturday"
        expect(this_week).to have_text "weekend meeting on sunday"

        later = page.find("[data-test-selector='meetings-table-later']")
        expect(later).to have_text "meeting on next monday"
        expect(later).to have_text "meeting on next friday"
      end
    end
  end

  describe "with start_of_week on sunday",
           with_settings: { start_of_week: 0 } do
    it "sorts upcoming meetings into buckets" do
      expect(subject).to have_http_status(:ok)

      content = page.find_by_id("content")
      expect(content).to have_text "Today"
      expect(content).to have_text "Tomorrow"
      expect(content).to have_text "Later this week"
      expect(content).to have_text "Next week and later"
      expect(content).to have_no_text "an earlier meeting"

      today = page.find("[data-test-selector='meetings-table-today']")
      expect(today).to have_text "meeting starting soon"

      tomorrow = page.find("[data-test-selector='meetings-table-tomorrow']")
      expect(tomorrow).to have_text "meeting starting tomorrow"

      this_week = page.find("[data-test-selector='meetings-table-this_week']")
      expect(this_week).to have_text "weekend meeting on saturday"
      expect(this_week).to have_text "weekend meeting on sunday"

      later = page.find("[data-test-selector='meetings-table-later']")
      expect(later).to have_text "meeting on next monday"
      expect(later).to have_text "meeting on next friday"
    end
  end

  describe "with start_of_week on saturday",
           with_settings: { start_of_week: 6 } do
    it "sorts upcoming meetings into buckets" do
      expect(subject).to have_http_status(:ok)

      content = page.find_by_id("content")
      expect(content).to have_text "Tomorrow"
      expect(content).to have_text "Next week and later"
      expect(content).to have_no_text "Later this week"
      expect(content).to have_no_text "an earlier meeting"

      today = page.find("[data-test-selector='meetings-table-today']")
      expect(today).to have_text "meeting starting soon"

      tomorrow = page.find("[data-test-selector='meetings-table-tomorrow']")
      expect(tomorrow).to have_text "meeting starting tomorrow"

      expect(page).to have_no_css("[data-test-selector='meetings-table-this_week']")

      later = page.find("[data-test-selector='meetings-table-later']")
      expect(later).to have_text "weekend meeting on saturday"
      expect(later).to have_text "weekend meeting on sunday"
      expect(later).to have_text "meeting on next monday"
      expect(later).to have_text "meeting on next friday"
    end
  end

  context "when showing past meetings" do
    let(:request) do
      filters = [{ "time" => { "operator" => "=", "values" => ["past"] } }].to_json
      sort = [["start_time", "desc"]].to_json
      get "/projects/#{project.id}/meetings", params: { filters:, sortBy: sort }
    end

    it "shows only one table" do
      expect(subject).to have_http_status(:ok)

      content = page.find_by_id("content")
      expect(content).to have_no_text "Today"
      expect(content).to have_no_text "Tomorrow"
      expect(content).to have_no_text "Later this week"
      expect(content).to have_no_text "Next week and later"

      table = page.find("[data-test-selector='Meetings::TableComponent']")
      expect(table).to have_text "an earlier meeting"
      expect(table).to have_no_text "meeting starting soon"
      expect(table).to have_no_text "meeting starting tomorrow"
      expect(table).to have_no_text "weekend meeting on sunday"
      expect(table).to have_no_text "meeting on next monday"
      expect(table).to have_no_text "meeting on next friday"
    end
  end

  describe "paginating options", with_settings: { start_of_week: 1 } do
    context "when requesting the first page with limit=1" do
      let(:request) { get "/projects/#{project.id}/meetings?limit=1" }

      it "shows a pagination" do
        expect(subject).to have_http_status(:ok)

        expect(page).to have_css("#meetings-table-footer-component")
        expect(page).to have_text "There is one more meeting"
        expect(page).to have_text "meeting on next monday"
        expect(page).to have_no_text "meeting on next friday"
      end
    end

    context "when requesting the second page with limit=100" do
      let(:request) { get "/projects/#{project.id}/meetings?limit=100" }

      it "shows a pagination" do
        expect(subject).to have_http_status(:ok)

        expect(page).to have_no_css("#meetings-table-footer-component")
        expect(page).to have_text "meeting on next monday"
        expect(page).to have_text "meeting on next friday"
      end
    end
  end
end
