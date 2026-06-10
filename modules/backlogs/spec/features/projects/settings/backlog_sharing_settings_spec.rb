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

RSpec.describe "Backlogs project settings sprint sharing", :js do
  let(:project) { create(:project) }
  let(:permissions) { %i[create_sprints share_sprint select_backlog_types_and_statuses] }

  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  before do
    login_as current_user
  end

  context "with share_sprint permission and enterprise token",
          with_ee: [:sprint_sharing] do
    it "displays and stores sprint sharing settings" do
      visit project_settings_backlog_sharing_path(project)

      expect(page).to have_link(
        "Sharing",
        href: project_settings_backlog_sharing_path(project)
      )

      # all radio buttons are present with no_sharing checked by default
      expect(page).to have_checked_field("Don't share")
      expect(page).to have_unchecked_field("All projects")
      expect(page).to have_unchecked_field("Subprojects")
      expect(page).to have_unchecked_field("Receive shared sprints")

      # no banners visible by default
      expect(page).to have_no_text(I18n.t("projects.settings.backlog_sharing.options.share_subprojects.info"))
      expect(page).to have_no_text(I18n.t("projects.settings.backlog_sharing.options.receive_shared.warning"))

      # selecting share_subprojects shows its info banner
      choose("Subprojects")
      expect(page).to have_text(I18n.t("projects.settings.backlog_sharing.options.share_subprojects.info"))
      expect(page).to have_no_text(I18n.t("projects.settings.backlog_sharing.options.receive_shared.warning"))

      # selecting receive_shared shows its warning banner
      choose("Receive shared sprints")
      expect(page).to have_text(I18n.t("projects.settings.backlog_sharing.options.receive_shared.warning"))
      expect(page).to have_no_text(I18n.t("projects.settings.backlog_sharing.options.share_subprojects.info"))

      # persists receive_shared
      click_button "Save"

      expect_and_dismiss_flash(type: :success, message: I18n.t(:notice_successful_update))
      expect(page).to have_checked_field("Receive shared sprints")
      expect(project.reload.sprint_sharing).to eq("receive_shared")

      # keeps the banner visible after persisting
      expect(page).to have_text(I18n.t("projects.settings.backlog_sharing.options.receive_shared.warning"))
      expect(page).to have_no_text(I18n.t("projects.settings.backlog_sharing.options.share_subprojects.info"))

      # selecting no_sharing hides all banners
      choose("Don't share")
      expect(page).to have_no_text(I18n.t("projects.settings.backlog_sharing.options.share_subprojects.info"))
      expect(page).to have_no_text(I18n.t("projects.settings.backlog_sharing.options.receive_shared.warning"))

      # persists no_sharing
      click_button "Save"

      expect_and_dismiss_flash(type: :success, message: I18n.t(:notice_successful_update))
      expect(page).to have_checked_field("Don't share")
      expect(project.reload.sprint_sharing).to eq("no_sharing")

      # keeps the banner hidden after persisting
      expect(page).to have_no_text(I18n.t("projects.settings.backlog_sharing.options.share_subprojects.info"))
      expect(page).to have_no_text(I18n.t("projects.settings.backlog_sharing.options.receive_shared.warning"))
    end

    context "when another project already shares with all projects" do
      let!(:other_project) { create(:project, name: "Sharer Project", sprint_sharing: "share_all_projects") }

      it "disables the all projects option with an explanation" do
        visit project_settings_backlog_sharing_path(project)

        expect(page).to have_field("All projects", disabled: true)
        expect(page).to have_text(
          I18n.t("projects.settings.backlog_sharing.options.share_all_projects.disabled_caption_anonymous")
        )
      end

      context "when the current user cannot see the other project" do
        let!(:other_project) { create(:project, public: false, name: "Sharer Project", sprint_sharing: "share_all_projects") }

        it "disables the all projects option without revealing the project name" do
          visit project_settings_backlog_sharing_path(project)

          expect(page).to have_field("All projects", disabled: true)
          expect(page).to have_text(
            I18n.t("projects.settings.backlog_sharing.options.share_all_projects.disabled_caption_anonymous")
          )
          expect(page).to have_no_text("Sharer Project")
        end
      end
    end
  end

  context "with share_sprint permission but no enterprise token" do
    context "without existing sharing setting in the project" do
      it "shows an enterprise token teaser" do
        visit project_settings_backlog_sharing_path(project)

        expect(page).to have_text("Share sprints across projects to align teams")

        expect(page).to have_no_field("Don't share")
        expect(page).to have_no_field("All projects")
        expect(page).to have_no_field("Subprojects")
        expect(page).to have_no_field("Receive shared sprints")
      end
    end

    context "with existing sharing setting in the project" do
      before do
        project.update!(sprint_sharing: "receive_shared")
      end

      it "shows the existing sharing setting but disables them except for `Don't share`" do
        visit project_settings_backlog_sharing_path(project)

        # All radio buttons are present with the selected option displayed.
        # But all except the "Don't share" option are disabled.
        expect(page).to have_unchecked_field("Don't share")
        expect(page).to have_unchecked_field("All projects", disabled: true)
        expect(page).to have_unchecked_field("Subprojects", disabled: true)
        expect(page).to have_checked_field("Receive shared sprints", disabled: true)

        choose("Don't share")

        click_button "Save"

        # Now that the `Don't share` option is selected, the large enterprise banner is displayed.
        expect(page).to have_text("Share sprints across projects to align teams")

        expect(page).to have_no_field("Don't share")
        expect(page).to have_no_field("All projects")
        expect(page).to have_no_field("Subprojects")
        expect(page).to have_no_field("Receive shared sprints")
      end
    end
  end

  context "without share_sprint permission" do
    let(:permissions) { %i[create_sprints select_backlog_types_and_statuses] }

    it "does not show the sharing tab and forbids direct route access" do
      visit project_settings_backlogs_path(project)

      expect(page).to have_heading(I18n.t(:label_backlogs))
      expect(page).to have_no_link(I18n.t("backlogs.sharing"))

      visit project_settings_backlog_sharing_path(project)

      expect(page).to have_text(I18n.t(:notice_not_authorized))
    end
  end
end
