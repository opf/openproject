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

require "rails_helper"

RSpec.describe "Backlogs project settings estimation unit", :js do
  let(:project) { create(:project) }
  let(:permissions) { %i[create_sprints share_sprint select_backlog_types_and_statuses] }

  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  current_user { user }

  context "when the feature flag is disabled", with_flag: { project_settings_estimation_unit: false } do
    it "does not show the units tab and forbids direct route access" do
      visit project_settings_backlogs_path(project)

      expect(page).to have_heading(I18n.t(:label_backlogs), exact: true)
      expect(page).to have_no_link(I18n.t("backlogs.estimation_unit"))

      visit project_settings_backlog_estimation_unit_path(project)

      expect(page).to have_text(I18n.t(:notice_file_not_found))
    end
  end

  context "when the feature flag is enabled", with_flag: { project_settings_estimation_unit: true } do
    it "displays and stores estimation unit settings" do
      visit project_settings_backlog_estimation_unit_path(project)

      expect(page).to have_link(
        "Units",
        href: project_settings_backlog_estimation_unit_path(project)
      )

      expect(page).to have_checked_field("Story points")
      expect(page).to have_unchecked_field("Work time estimate")
      expect(page).to have_unchecked_field("None")

      choose("Work time estimate")
      click_button "Save"

      expect_and_dismiss_flash(type: :success, message: I18n.t(:notice_successful_update))
      expect(page).to have_checked_field("Work time estimate")
      expect(project.reload.estimation_unit).to eq("time")

      choose("None")
      click_button "Save"

      expect_and_dismiss_flash(type: :success, message: I18n.t(:notice_successful_update))
      expect(page).to have_checked_field("None")
      expect(project.reload.estimation_unit).to eq("none")

      choose("Story points")
      click_button "Save"

      expect_and_dismiss_flash(type: :success, message: I18n.t(:notice_successful_update))
      expect(page).to have_checked_field("Story points")
      expect(project.reload.estimation_unit).to eq("story_points")
    end

    context "without select_backlog_types_and_statuses permission" do
      let(:permissions) { %i[create_sprints share_sprint] }

      it "forbids direct route access" do
        visit project_settings_backlog_estimation_unit_path(project)

        expect(page).to have_text(I18n.t(:notice_not_authorized))
      end
    end
  end
end
