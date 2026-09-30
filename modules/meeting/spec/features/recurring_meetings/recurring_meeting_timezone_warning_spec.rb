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
require_relative "../../support/pages/recurring_meeting/show"

RSpec.describe "Recurring meetings timezone warning",
               :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }

  let(:amsterdam_user) do
    create(:user,
           preferences: { time_zone: "Europe/Amsterdam" },
           member_with_permissions: { project => %i[view_meetings edit_meetings] })
  end

  let(:tokyo_user) do
    create(:user,
           preferences: { time_zone: "Asia/Tokyo" },
           member_with_permissions: { project => %i[view_meetings edit_meetings] })
  end

  let(:show_page) { Pages::RecurringMeeting::Show.new(recurring_meeting) }

  context "when user timezone maps to same abbreviation as meeting timezone" do
    let(:recurring_meeting) do
      create :recurring_meeting,
             project:,
             time_zone: "Europe/Berlin"
    end

    before do
      login_as amsterdam_user
      show_page.visit!
    end

    it "does not show timezone warning (Bug #71404)" do
      show_page.edit_meeting_series

      show_page.within_modal "Edit Meeting" do
        expect(page).to have_no_text "Time zone difference"
        expect(page).to have_no_text "The dates below are referencing the time zone"
      end
    end
  end

  context "when user timezone differs from meeting timezone" do
    let(:recurring_meeting) do
      create :recurring_meeting,
             project:,
             time_zone: "Europe/Berlin"
    end

    before do
      login_as tokyo_user
      show_page.visit!
    end

    it "shows timezone warning" do
      show_page.edit_meeting_series

      show_page.within_modal "Edit Meeting" do
        expect(page).to have_text "Time zone difference"
        expect(page).to have_text "The dates below are referencing the time zone"
      end
    end
  end
end
