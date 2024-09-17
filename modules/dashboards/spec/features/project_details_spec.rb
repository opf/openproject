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

require_relative "../support/pages/dashboard"

RSpec.describe "Project details widget on dashboard", :js do
  let(:system_version) { create(:version, sharing: "system") }

  let!(:project) do
    create(:project, members: { other_user => role })
  end

  let(:permissions) do
    %i[view_dashboards
       manage_dashboards]
  end

  let(:editing_permissions) do
    %i[view_dashboards
       manage_dashboards
       edit_project]
  end

  let(:role) do
    create(:project_role, permissions:)
  end

  let(:read_only_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:editing_user) do
    create(:user,
           member_with_permissions: { project => editing_permissions },
           firstname: "Cool",
           lastname: "Guy")
  end
  let(:other_user) do
    create(:user,
           firstname: "Other",
           lastname: "User")
  end

  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  def add_project_details_widget
    dashboard_page.visit!
    dashboard_page.add_widget(1, 1, :within, "Project details")

    dashboard_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")
  end

  before do
    login_as current_user
    add_project_details_widget
  end

  context "without editing permissions" do
    let(:current_user) { read_only_user }

    it "displays the deprecated message" do
      # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
      details_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      within(details_widget.area) do
        expect(page)
          .to have_content("Project details have now moved to a column on the right edge of this page.")
        expect(page).to have_content(
          <<~TEXT.strip
            Starting with version 14.0, project attributes can be grouped \
            in sections and enabled and disabled at a project level.
          TEXT
        )
        expect(page).to have_content(
          <<~TEXT.strip
            This widget can now be removed or replaced. \
            It will be deleted in subsequent versions.
          TEXT
        )
      end
    end
  end

  context "with editing permissions" do
    let(:current_user) { editing_user }

    it "displays the deprecated message" do
      # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
      details_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      within(details_widget.area) do
        expect(page)
          .to have_content("Project details have now moved to a column on the right edge of this page.")
        expect(page).to have_content(
          <<~TEXT.strip
            Starting with version 14.0, project attributes can be grouped \
            in sections and enabled and disabled at a project level.
          TEXT
        )
        expect(page).to have_content(
          <<~TEXT.strip
            This widget can now be removed or replaced. \
            It will be deleted in subsequent versions.
          TEXT
        )
      end
    end
  end

  context "when project has Activity module enabled" do
    let(:current_user) { read_only_user }

    it 'has a "Project activity" entry in More menu linking to the project activity page' do
      details_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      details_widget.click_menu_item("Project details activity")
      expect(page).to have_current_path(project_activity_index_path(project), ignore_query: true)
      expect(page).to have_checked_field(id: "event_types_project_attributes")
    end
  end
end
