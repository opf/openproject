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

RSpec.describe WorkPackageTypes::ProjectsTab::TreeComponent, type: :component do
  shared_let(:type) { create(:type) }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Hardware") }
  shared_let(:other_variant) { create(:type_variant, type:, variant_name: "Firmware") }

  let(:builder) { ActionView::Helpers::FormBuilder.new("", nil, vc_test_controller.view_context, {}) }

  def render_tree(projects)
    render_inline(
      described_class.new(variant:,
                          nodes: Project.build_projects_hierarchy(projects),
                          builder:,
                          form_name: "project_ids")
    )
  end

  it "renders a node per project" do
    parent = create(:project, name: "Parent")
    child = create(:project, name: "Child", parent:)

    render_tree([parent, child])

    expect(page).to have_text("Parent")
    expect(page).to have_text("Child")
  end

  it "lets a parent be ticked without ticking its children" do
    parent = create(:project, name: "Parent")
    create(:project, name: "Child", parent:)

    render_tree(Project.order(:lft))

    expect(page).to have_css("[data-node-id='#{parent.id}'][data-select-strategy='self']", visible: :all)
    expect(page).to have_no_css("[data-select-strategy='descendants']", visible: :all)
  end

  context "when a project applies another variant of the type" do
    let!(:project) { create(:project, name: "Bookshop", types: [other_variant]) }

    it "labels the node with that variant" do
      render_tree([project])

      expect(page).to have_css(".text-bold", text: other_variant.composite_name)
    end
  end

  context "when a project applies the variant being edited" do
    let!(:project) { create(:project, name: "Bookshop", types: [variant]) }

    it "carries no label" do
      render_tree([project])

      expect(page).to have_text("Bookshop")
      expect(page).to have_no_css(".text-bold")
    end

    it "cannot be picked again" do
      render_tree([project])

      expect(page).to have_css("[aria-disabled='true']")
    end
  end

  context "when a project does not use the type at all" do
    let!(:project) { create(:project, name: "Bookshop", types: []) }

    it "carries no label" do
      render_tree([project])

      expect(page).to have_text("Bookshop")
      expect(page).to have_no_css(".text-bold")
    end
  end
end
