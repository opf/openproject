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

RSpec.describe Projects::Settings::WorkPackages::Types::ListComponent,
               type: :component,
               with_flag: { type_variants: true } do
  include Rails.application.routes.url_helpers

  # acts_as_list overrides positions passed at creation, so pin them afterwards.
  # The family order is Epic(1) then Bug(2), while the variant's own position (9)
  # is scoped to its parent and must not influence the row order.
  shared_let(:epic) { create(:type, name: "Epic").tap { |type| type.update_column(:position, 1) } }
  shared_let(:bug) { create(:type, name: "Bug").tap { |type| type.update_column(:position, 2) } }
  shared_let(:design) do
    create(:type, name: "Design", parent: epic).tap { |type| type.update_column(:position, 9) }
  end

  subject(:component) { described_class.new(project:) }

  context "when a family is active through its parent" do
    let(:project) { create(:project, types: [bug]) }

    before { render_inline(component) }

    it "names the type" do
      expect(page).to have_text("Bug")
    end

    it "offers the remove action" do
      expect(page).to have_button("Remove from project", visible: :all)
      expect(page).to have_css(
        "form[action='#{project_settings_work_packages_type_path(project, bug)}']",
        visible: :all
      )
    end
  end

  context "when a family is active through a variant" do
    let(:project) { create(:project, types: [design]) }

    before { render_inline(component) }

    it "names the parent type, not the composite name" do
      expect(page).to have_text("Epic")
      expect(page).to have_no_text("Epic: Design")
    end

    # normalize_ws because render_inline keeps the newline between the two Text
    # components that a browser lays out on one line.
    it "names the active variant after the parent it presents as" do
      expect(page).to have_text("Variant: Design", normalize_ws: true)
    end

    it "points the remove action at the variant" do
      expect(page).to have_css(
        "form[action='#{project_settings_work_packages_type_path(project, design)}']",
        visible: :all
      )
    end
  end

  context "with several active families" do
    let(:project) { create(:project, types: [design, bug]) }

    before { render_inline(component) }

    it "orders rows by the family's position rather than the member's" do
      expect(page.all("[data-test-selector^='project-types-row-']").pluck(:"data-test-selector"))
        .to eq(["project-types-row-#{design.id}", "project-types-row-#{bug.id}"])
    end
  end

  context "without any active type" do
    # The workspace factory pushes the standard type whenever types is empty.
    let(:project) { create(:project, types: [], no_types: true) }

    before { render_inline(component) }

    it "renders the empty state" do
      expect(page).to have_text("No types are active in this project")
    end
  end

  describe "expanded family rows" do
    shared_let(:stranger) { create(:project) }
    shared_let(:global_variant) { create(:type, name: "Global bug", parent: bug) }

    let(:project) { create(:project, types: [bug]) }

    before do
      create(:type, name: "Our bug", parent: bug, project:)
      create(:type, name: "Their bug", parent: bug, project: stranger)
      render_inline(component)
    end

    it "names the family" do
      expect(page).to have_text("Bug")
    end

    # Global variants apply here too, so the project administrator has to see them.
    it "lists the global variant" do
      expect(page).to have_text("Global bug")
    end

    it "lists the project's own variant" do
      expect(page).to have_text("Our bug")
    end

    # The isolation criterion, checked where a user would actually notice it.
    it "never mentions another project's variant" do
      expect(page).to have_no_text("Their bug")
    end

    it "marks the project's own variant as confined to it" do
      expect(page).to have_text("Only available in this project")
    end
  end

  describe "actions on a variant" do
    let(:project) { create(:project, types: [bug]) }
    let!(:owned) { create(:type, name: "Our bug", parent: bug, project:) }

    context "with the permission to manage the project's variants" do
      current_user { create(:user, member_with_permissions: { project => %i[manage_project_variants] }) }

      before { render_inline(component) }

      it "offers to add a variant" do
        expect(page).to have_link("Add a variant for this project")
      end

      it "points the edit action at the project-scoped details tab" do
        expect(page).to have_css(
          "a[href='#{edit_project_settings_work_packages_types_variant_details_path(project, owned)}']",
          visible: :all
        )
      end
    end

    # Someone who may only select types for the project has nothing to manage here.
    context "without the permission" do
      current_user { create(:user, member_with_permissions: { project => %i[manage_types] }) }

      before { render_inline(component) }

      it "does not offer to add a variant" do
        expect(page).to have_no_link("Add a variant for this project")
      end
    end
  end

  context "when the family's only variant belongs to another project" do
    let(:project) { create(:project, types: [bug]) }

    before do
      create(:type, name: "Theirs", parent: bug, project: create(:project))
      render_inline(component)
    end

    # There is nothing here for this project to switch to, so offering the action would lie.
    it "hides the switch action" do
      expect(page).to have_no_link("Switch variant", visible: :all)
    end
  end

  context "when the family has a variant this project owns" do
    let(:project) { create(:project, types: [bug]) }

    before do
      create(:type, name: "Ours", parent: bug, project:)
      render_inline(component)
    end

    it "offers the switch action" do
      expect(page).to have_link("Switch variant", visible: :all)
    end
  end
end
