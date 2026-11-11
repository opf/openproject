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

RSpec.describe Admin::CustomFields::Hierarchy::ChangeItemParentDialogComponent, type: :component,
                                                                                with_ee: %i[custom_field_hierarchies] do
  let(:custom_field) { create(:wp_custom_field, :hierarchy) }
  let(:root) { custom_field.hierarchy_root }
  let(:project) { create(:project, name: "Scrum project") }
  let(:other_project) { create(:project, name: "Demo project") }
  let!(:germany) { create(:hierarchy_item, parent: root, label: "Germany") }
  let!(:france) { create(:hierarchy_item, parent: root, label: "France") }
  let!(:cologne) { create(:hierarchy_item, parent: germany, label: "Cologne", project:) }
  let!(:lyon) { create(:hierarchy_item, parent: france, label: "Lyon", project: other_project) }

  let(:tree_item) { ->(label) { page.find("[role='treeitem']", text: label, match: :prefer_exact, visible: :all) } }

  before { render_inline(described_class.new(custom_field:, hierarchy_item:)) }

  context "when moving a global item" do
    let(:hierarchy_item) { create(:hierarchy_item, parent: france, label: "Paris") }

    it "does not offer project items as new parent", :aggregate_failures do
      expect(tree_item.("Cologne")["aria-disabled"]).to eq("true")
      expect(tree_item.("Lyon")["aria-disabled"]).to eq("true")
      expect(tree_item.("Germany")["aria-disabled"]).to eq("false")
    end

    it "marks project items as project-specific" do
      expect(page).to have_css("[role='treeitem'] .color-fg-muted", exact_text: "Project-specific", visible: :all)
    end
  end

  context "when moving a project item" do
    let(:hierarchy_item) { create(:hierarchy_item, parent: france, label: "Ehrenfeld", project:) }

    it "offers global items and items of the same project only", :aggregate_failures do
      expect(tree_item.("Cologne")["aria-disabled"]).to eq("false")
      expect(tree_item.("Lyon")["aria-disabled"]).to eq("true")
    end
  end
end
