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

require "rails_helper"

RSpec.describe WorkPackageTypes::ProjectsTab::RowMenuComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware") }
  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [bug]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }

  let(:variant) { bug.default_variant }
  let(:projects) { [foundry] }
  let(:menu) { page.find("ul[role='menu']") }

  before { render_inline(described_class.new(variant:, invoker: foundry, projects:)) }

  it "loads into the invoking row's menu" do
    expect(page).to have_css("##{described_class.menu_id(foundry)}-list")
  end

  it "reports the scope it acts on to the menu source" do
    expect(menu["data-sortable-lists--menu-source-target"]).to eq("menu")
    expect(menu["data-sortable-lists-scope-count"]).to eq("1")
  end

  it "opens the switch and removal dialogs for the invoking project" do
    expect(menu).to have_link("Switch variant",
                              href: new_type_projects_switch_path(type_id: bug.id, project_ids: [foundry.id]))
    expect(menu).to have_link("Remove type from this project",
                              href: new_type_projects_link_deletion_path(type_id: bug.id, project_ids: [foundry.id]))
    expect(menu).to have_css("a[data-controller='async-dialog']", count: 2)
  end

  context "with several projects" do
    let(:projects) { [bookshop, foundry] }

    it "reports their count" do
      expect(menu["data-sortable-lists-scope-count"]).to eq("2")
    end

    it "opens the bulk dialogs for all of them" do
      ids = [bookshop.id, foundry.id]

      expect(menu).to have_link("Switch variant", href: new_type_projects_switch_path(type_id: bug.id, project_ids: ids))
      expect(menu).to have_link("Remove type from these projects",
                                href: new_type_projects_link_deletion_path(type_id: bug.id, project_ids: ids))
    end
  end

  context "with a type that has no variant to switch to" do
    shared_let(:task) { create(:type, name: "Task") }

    let(:variant) { task.default_variant }

    it "only offers removal" do
      expect(menu).to have_no_link("Switch variant")
      expect(menu).to have_link("Remove type from this project")
    end
  end
end
