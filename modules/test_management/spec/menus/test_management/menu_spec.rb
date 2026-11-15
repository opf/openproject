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

RSpec.describe TestManagement::Menu do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }
  let(:params) { { controller: "test_management/test_cases" } }
  let(:menu) { described_class.new(project:, params:, user:) }

  describe ".section_for" do
    it "maps the cases controller" do
      expect(described_class.section_for("test_management/test_cases")).to eq("cases")
      expect(described_class.section_for("projects")).to be_nil
    end
  end

  context "with vertical navigation" do
    before { create(:tm_project_setting, project:, navigation_layout: "vertical") }

    it "lists cases in the sidebar menu" do
      expect(menu.menu_items.first.children.map(&:href))
        .to eq([project_test_management_test_cases_path(project)])
    end
  end

  context "with horizontal navigation" do
    before { create(:tm_project_setting, project:, navigation_layout: "horizontal") }

    it "hides the sidebar menu items" do
      expect(menu).to be_horizontal_navigation
      expect(menu.menu_items).to be_empty
    end
  end

  context "without the module" do
    let(:project) { create(:project, enabled_module_names: []) }

    it "has no visible sections" do
      expect(menu.visible_sections).to be_empty
      expect(menu.menu_items.first.children).to be_empty
    end
  end
end
