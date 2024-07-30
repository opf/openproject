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

require "spec_helper"
require_relative "../support/pages/calendar"
require_relative "shared_context"

RSpec.describe "Calendar",
               "Creating a view from a Global Context",
               :js,
               :with_cuprite do
  include_context "with calendar full access"

  let(:calendars_page) { Pages::Calendar.new nil }

  before do
    login_as user
  end

  context "within the global index page" do
    before do
      visit calendars_path
    end

    context "when clicking on the create button" do
      before do
        calendars_page.click_on_create_button
      end

      it "navigates to the global create form" do
        expect(page).to have_current_path new_calendar_path
        expect(page).to have_content I18n.t(:label_new_calendar)
      end
    end
  end

  context "within the global create page" do
    before do
      visit new_calendar_path
    end

    context "with all fields set" do
      before do
        wait_for_reload # Halt until the project autocompleter is ready

        calendars_page.set_title("Batman's Itinerary")
        calendars_page.set_project(project)
        calendars_page.set_public
        calendars_page.set_favoured
        calendars_page.click_on_submit

        wait_for_reload
      end

      it "creates a view and redirects me to it" do
        expect(page).to have_text(I18n.t(:notice_successful_create))
        expect(page).to have_current_path(project_calendar_path(project, Query.last), ignore_query: true)
        expect(page).to have_text("Batman's Itinerary")
      end
    end

    context "when missing a required field" do
      describe "title" do
        before do
          wait_for_reload # Halt until the project autocompleter is ready

          calendars_page.set_project(project)
          calendars_page.click_on_submit
        end

        it "renders a required attribute validation error" do
          expect(Query.all).to be_empty

          # Required HTML attribute just warns
          expect(page).to have_current_path(new_calendar_path)
        end
      end

      describe "project_id" do
        before do
          calendars_page.set_title("Batman's Itinerary")
          calendars_page.click_on_submit

          wait_for_reload
        end

        it "renders a required attribute validation error" do
          expect(Query.all).to be_empty

          expect(page).to have_text("Project can't be blank.")
        end
      end
    end

    describe "cancel button" do
      context "when it's clicked" do
        before do
          calendars_page.click_on_cancel_button
        end

        it "navigates back to the global index page" do
          expect(page).to have_current_path(calendars_path)
        end
      end
    end
  end
end
