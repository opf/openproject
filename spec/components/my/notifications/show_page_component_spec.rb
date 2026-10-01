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

RSpec.describe My::Notifications::ShowPageComponent, type: :component do
  let(:user) { create(:user) }
  # create(:user) already seeds the global (project-less) notification setting.
  let(:global_setting) { user.notification_settings.find_by!(project: nil) }

  subject(:rendered_component) do
    with_request_url("/my/notifications") do
      render_inline(
        described_class.new(
          user:,
          global_notification_setting: global_setting,
          update_participating_url: { action: "update_participating" },
          update_non_participating_url: { action: "update_non_participating" },
          update_date_alerts_url: { action: "update_date_alerts" },
          new_project_settings_url: "/my/project_notifications/new",
          edit_project_settings_url: ->(project_id) { "/my/project_notifications/#{project_id}/edit" },
          project_setting_url: ->(project_id) { "/my/project_notifications/#{project_id}" }
        )
      )
    end
  end

  context "with project-specific settings" do
    let(:project) { create(:project) }
    let!(:project_setting) { create(:notification_setting, user:, project:) }

    it "renders the list header and the add-project action", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-header") do |header|
        expect(header).to have_heading(I18n.t("my_account.notifications.project_specific_settings.list_header"))
      end
      expect(rendered_component).to have_link(
        I18n.t("my_account.notifications.project_specific_settings.add_button"),
        href: "/my/project_notifications/new"
      )
    end

    it "renders a row per project-specific setting with an edit/delete actions menu", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-row", text: project.name) do |row|
        expect(row).to have_button(accessible_name: I18n.t(:label_open_menu))
        expect(row).to have_link(I18n.t(:button_edit), href: "/my/project_notifications/#{project.id}/edit")
        expect(row).to have_link(I18n.t(:button_delete), href: "/my/project_notifications/#{project.id}")
      end
    end
  end

  context "without project-specific settings" do
    it_behaves_like "rendering Blank Slate",
                    heading: I18n.t(:label_nothing_display)
  end
end
