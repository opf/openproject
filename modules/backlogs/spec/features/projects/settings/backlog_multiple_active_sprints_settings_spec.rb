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

RSpec.describe "Backlogs project settings multiple active sprints", :js do
  let(:project) { create(:project) }
  let(:permissions) { %i[create_sprints select_backlog_types_and_statuses share_sprint] }
  let(:current_user) { create(:user, member_with_permissions: { project => permissions }) }

  before { login_as current_user }

  it "shows the multiple active sprints tab in the navigation" do
    visit project_settings_backlog_multiple_active_sprints_path(project)

    expect(page).to have_link(
      "Multiple active sprints",
      href: project_settings_backlog_multiple_active_sprints_path(project)
    )
  end

  context "without an enterprise token for multiple_active_sprints" do
    it "renders an enterprise banner instead of the toggle" do
      visit project_settings_backlog_multiple_active_sprints_path(project)

      expect(page).to have_css(".op-enterprise-banner")
      expect(page).to have_no_css(".ToggleSwitch")
    end
  end

  context "with an enterprise token for multiple_active_sprints", with_ee: %i[multiple_active_sprints] do
    context "when sprint sharing is disabled" do
      it "renders the toggle switch" do
        visit project_settings_backlog_multiple_active_sprints_path(project)

        expect(page).to have_css(".ToggleSwitch")
        expect(page).to have_no_text("not available")
      end

      context "when toggling on" do
        it "enables the setting" do
          visit project_settings_backlog_multiple_active_sprints_path(project)

          expect(page).to have_css(".ToggleSwitch")
          expect(page).to have_no_css(".ToggleSwitch--checked")
          find(".ToggleSwitch").click
          expect(page).to have_css(".ToggleSwitch--checked")

          expect(project.reload.allow_multiple_active_sprints).to be(true)
        end
      end

      context "when toggling off" do
        before { project.update!(allow_multiple_active_sprints: true) }

        it "disables the setting" do
          visit project_settings_backlog_multiple_active_sprints_path(project)

          expect(page).to have_css(".ToggleSwitch--checked")
          find(".ToggleSwitch").click
          expect(page).to have_no_css(".ToggleSwitch--checked")

          expect(project.reload.allow_multiple_active_sprints).to be(false)
        end
      end

      context "when multiple active sprints is already enabled and multiple sprints are active" do
        before do
          project.update!(allow_multiple_active_sprints: true)
          create(:sprint, project:, status: "active",
                          start_date: Time.zone.today - 1, finish_date: Time.zone.today + 1)
          create(:sprint, project:, status: "active",
                          start_date: Time.zone.today - 1, finish_date: Time.zone.today + 1)
        end

        it "renders the toggle disabled with a warning" do
          visit project_settings_backlog_multiple_active_sprints_path(project)

          expect(page).to have_css(".ToggleSwitch--disabled")
          expect(page).to have_text("Multiple sprints are currently active")
        end
      end
    end

    context "when sprint sharing is enabled" do
      before { project.update!(sprint_sharing: "receive_shared") }

      it "renders the not-available message with a link to sprint sharing settings" do
        visit project_settings_backlog_multiple_active_sprints_path(project)

        expect(page).to have_text("not available")
        expect(page).to have_link("sprint sharing", href: project_settings_backlog_sharing_path(project))
        expect(page).to have_no_css(".ToggleSwitch")
      end
    end
  end
end
