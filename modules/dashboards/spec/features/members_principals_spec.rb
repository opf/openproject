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

RSpec.describe "Dashboard page members", :js do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type], description: "My **custom** description") }

  shared_let(:permissions) do
    %i[manage_dashboards
       view_dashboards
       view_members]
  end

  shared_let(:user) do
    create(:user,
           firstname: "Foo",
           lastname: "Bar",
           member_with_permissions: { project => permissions })
  end

  shared_let(:group) do
    create(:group,
           name: "DEV Team",
           member_with_permissions: { project => permissions })
  end

  shared_let(:placeholder) do
    create(:placeholder_user,
           name: "DEVELOPER PLACEHOLDER",
           member_with_permissions: { project => permissions })
  end

  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard_page.visit!
  end

  it "renders the default view, allows altering and saving" do
    # within top-right area, add an additional widget
    dashboard_page.add_widget(1, 1, :within, "Members")

    members_block = page.find(".widget-box", text: "MEMBERS")

    within(members_block) do
      user_link = find("op-principal a", text: user.name)
      expect(user_link["href"]).to end_with user_path(user.id)

      group_link = find("op-principal a", text: group.name)
      expect(group_link["href"]).to end_with show_group_path(group.id)

      placeholder_link = find("op-principal a", text: placeholder.name)
      expect(placeholder_link["href"]).to end_with placeholder_user_path(placeholder.id)
    end
  end
end
