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
require_relative "shared_context"

RSpec.describe "Team Planner",
               "Creating a view from a Global Context",
               :js,
               :with_cuprite,
               with_ee: %i[team_planner_view] do
  include_context "with team planner full access"

  context "within the overview page" do
    before do
      visit team_planners_path
    end

    context "when clicking on the create button" do
      before do
        team_planner.click_on_create_button
      end

      it "navigates to the global create form" do
        expect(page).to have_current_path(new_team_planners_path)
        expect(page).to have_content I18n.t("team_planner.label_new_team_planner")
      end
    end
  end

  context "within the global create page" do
    before do
      visit new_team_planners_path
    end

    context "with all fields set" do
      before do
        wait_for_reload # Halt until the project autocompleter is ready

        team_planner.set_title("Gotham Renewal")
        team_planner.set_project(project)
        team_planner.set_public
        team_planner.set_favoured
        team_planner.click_on_submit

        wait_for_reload
      end

      it "creates a view and redirects me to it" do
        expect(page).to have_text(I18n.t(:notice_successful_create))
        expect(page).to have_current_path(project_team_planner_path(project, Query.last), ignore_query: true)
        expect(page).to have_text("Gotham Renewal")
      end
    end

    context "when missing a required field" do
      describe "title" do
        before do
          wait_for_reload # Halt until the project autocompleter is ready

          team_planner.set_project(project)
          team_planner.click_on_submit
        end

        it "renders a required attribute validation error" do
          expect(Query.all).to be_empty

          # Required HTML attribute just warns
          expect(page).to have_current_path(new_team_planners_path)
        end
      end

      describe "project_id" do
        before do
          team_planner.set_title("Gotham Renewal")
          team_planner.click_on_submit

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
          team_planner.click_on_cancel_button
        end

        it "navigates back to the overview page" do
          expect(page).to have_current_path(team_planners_path)
        end
      end
    end
  end
end
