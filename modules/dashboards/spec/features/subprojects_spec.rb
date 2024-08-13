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

RSpec.describe "Subprojects widget on dashboard", :js do
  let!(:project) do
    create(:project, parent: parent_project)
  end

  let!(:child_project) do
    create(:project, parent: project)
  end
  let!(:archived_child_project) do
    create(:project, :archived, parent: project)
  end
  let!(:invisible_child_project) do
    create(:project, parent: project)
  end
  let!(:grandchild_project) do
    create(:project, parent: child_project)
  end
  let!(:parent_project) do
    create(:project)
  end

  let(:permissions) do
    %i[view_dashboards
       manage_dashboards]
  end

  let(:role) do
    create(:project_role, permissions:)
  end

  let(:user) do
    create(:user).tap do |u|
      create(:member, project:, roles: [role], user: u)
      create(:member, project: child_project, roles: [role], user: u)
      create(:member, project: archived_child_project, roles: [role], user: u)
      create(:member, project: grandchild_project, roles: [role], user: u)
      create(:member, project: parent_project, roles: [role], user: u)
    end
  end
  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  context "as a user" do
    current_user { user }

    it "can add the widget listing active subprojects the user is member of", :aggregate_failures do
      dashboard_page.visit!
      dashboard_page.add_widget(1, 1, :within, "Subprojects")

      subprojects_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

      expect(page)
        .to have_link(child_project.name)

      within(subprojects_widget.area) do
        expect(page)
          .to have_link(child_project.name)
        expect(page)
          .to have_no_link(archived_child_project.name)
        expect(page)
          .to have_no_link(grandchild_project.name)
        expect(page)
          .to have_no_link(invisible_child_project.name)
        expect(page)
          .to have_no_link(parent_project.name)
        expect(page)
          .to have_no_link(project.name)
      end
    end
  end

  context "as an admin" do
    current_user { create(:admin) }

    it "can add the widget listing all active subprojects", :aggregate_failures do
      dashboard_page.visit!
      dashboard_page.add_widget(1, 2, :within, "Subprojects")

      subprojects_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(2)")

      within(subprojects_widget.area) do
        expect(page)
          .to have_link(child_project.name)
        expect(page)
          .to have_no_link(archived_child_project.name)
        expect(page)
          .to have_no_link(grandchild_project.name)
        expect(page)
          .to have_link(invisible_child_project.name) # admins can see projects they are not a member of
        expect(page)
          .to have_no_link(parent_project.name)
        expect(page)
          .to have_no_link(project.name)
      end
    end
  end
end
