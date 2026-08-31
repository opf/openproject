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
               "the variants a project owns",
               type: :component,
               with_flag: { type_variants: true } do
  include Rails.application.routes.url_helpers

  shared_let(:bug) { create(:type, name: "Bug").tap { |type| type.update_column(:position, 1) } }
  shared_let(:project) { create(:project, types: [bug]) }
  shared_let(:stranger) { create(:project) }

  shared_let(:global) { create(:type_variant, type: bug, variant_name: "Mobile") }
  shared_let(:ours) { create(:project_owned_type_variant, type: bug, project:, variant_name: "Internal review") }
  shared_let(:theirs) { create(:project_owned_type_variant, type: bug, project: stranger, variant_name: "Demo only") }

  subject(:component) { described_class.new(project:) }

  def group(variant) = page.find("[data-test-selector='project-types-row-#{variant.id}']")
  def row(variant) = page.find("[data-test-selector='project-types-variant-#{variant.id}']")

  def switch_path(target)
    new_project_settings_work_packages_type_switch_path(project, bug, target_id: target.id)
  end

  def header_of(variant) = group(variant).find(".op-border-box-list-header")

  def use_variant(variant)
    project.project_types.find_by(type: bug).update!(variant:)
  end

  context "when the member may manage them" do
    current_user do
      create(:user, member_with_permissions: { project => %i[view_project manage_project_variants] })
    end

    before { render_inline(component) }

    it "lists the variant the project owns" do
      expect(page).to have_text("Internal review")
    end

    it "lists the global variants alongside it" do
      expect(page).to have_text("Mobile")
    end

    # The point of the whole feature: one project's variant is invisible to the others.
    it "never lists another project's variant" do
      expect(page).to have_no_text("Demo only")
    end

    # The type heads the group, as bold as the variant names below it.
    it "sets the type's name in the same weight as its variants" do
      expect(header_of(bug.default_variant)).to have_css(".text-bold", text: "Bug")
    end

    it "captions the variant the project owns as the project's own" do
      expect(row(ours)).to have_text("Project-specific variant")
    end

    it "captions a variant every project may use plainly" do
      expect(row(global)).to have_text("Variant")
      expect(row(global)).to have_no_text("Project-specific variant")
    end

    # Which variant is in use is a state, not something to act on, and ownership is a plain
    # statement about the row it sits on. Neither is a label.
    it "labels nothing" do
      expect(page).to have_no_css(".Label")
    end

    it "offers to add one" do
      expect(page).to have_link(
        "Add a project-specific variant",
        href: new_creation_wizard_types_path(in_project_id: project, type_id: bug.id)
      )
    end

    # The name is the affordance administration's list already uses. The others have no page
    # this reader may open: the type's own configuration and the global variants are
    # administration's.
    it "links the name of the variant it owns" do
      expect(page).to have_link(
        "Internal review",
        href: edit_type_details_path(in_project_id: project, type_id: bug.id, variant_id: ours.id)
      )
    end

    it "leaves a global variant's name unlinked" do
      expect(page).to have_text("Mobile")
      expect(page).to have_no_link("Mobile")
    end

    it "leaves the type's own name unlinked" do
      expect(page).to have_no_link("Bug")
    end

    it "offers to configure the one it owns" do
      expect(page).to have_link(
        "Edit",
        href: edit_type_details_path(in_project_id: project, type_id: bug.id, variant_id: ours.id)
      )
    end

    # Set apart the way the type's own menu sets removal apart: a destructive action should not sit
    # flush against the one above it.
    it "puts a divider before deleting the one it owns" do
      items = row(ours).all("action-menu li").map do |item|
        item[:class].to_s.include?("ActionList-sectionDivider") ? "---" : item.text.strip
      end

      expect(items.last(2)).to eq(["---", "Delete"])
    end

    it "offers to delete the one it owns" do
      expect(page).to have_css(
        "form[action='#{type_variant_path(in_project_id: project, type_id: bug.id, id: ours.id)}']",
        visible: :all
      )
    end

    # Authoring the project's own variant and putting it to use are one job: leaving the second
    # half to whoever administers the instance's types makes the first half pointless.
    it "offers the variant it owns for use" do
      expect(row(ours)).to have_link(
        "Use in this project",
        href: new_project_settings_work_packages_type_switch_path(project, bug, target_id: ours.id)
      )
    end

    # Which of the variants it may use the project runs on is the project's own choice.
    it "offers a global variant for use as well" do
      expect(row(global)).to have_link(
        "Use in this project",
        href: new_project_settings_work_packages_type_switch_path(project, bug, target_id: global.id)
      )
    end

    it "offers no way to take the type out of the project" do
      expect(page).to have_no_button("Remove from project", visible: :all)
    end

    # A global variant belongs to every project, so no single one may edit or remove it.
    # The type's own menu gathers everything that can be done to it, while the row at the foot of
    # the group stays: a reader scanning the variants finds it there without opening a menu.
    it "offers to add a project-specific variant from the type's menu as well as the last row" do
      expect(header_of(bug.default_variant)).to have_link(
        "Add a project-specific variant",
        href: new_creation_wizard_types_path(in_project_id: project, type_id: bug.id)
      )
      expect(group(bug.default_variant)).to have_link("Add a project-specific variant", count: 2)
    end

    it "offers no action on a global variant" do
      expect(page).to have_no_link(
        "Edit",
        href: edit_type_details_path(in_project_id: project, type_id: bug.id, variant_id: global.id)
      )
    end
  end

  # The reader opening a group is choosing among the variants this project may use, so that is
  # what the count counts.
  describe "the count on a type" do
    shared_let(:plain) { create(:type, name: "Plain").tap { |type| type.update_column(:position, 2) } }

    current_user { create(:user, member_with_permissions: { project => %i[view_project] }) }

    before do
      create(:project_type, project:, type: plain)
      render_inline(component)
    end

    it "counts the variants the project may use" do
      expect(group(bug.default_variant)).to have_css(".Counter", text: "2")
    end

    it "counts nothing where there is nothing to choose from" do
      expect(group(plain.default_variant)).to have_no_css(".Counter")
    end
  end

  # A type the project uses no named variant of shows an empty group, as it does on the types
  # index, rather than a blank slate telling the reader nothing they cannot see.
  describe "a type with no variant the project may use" do
    shared_let(:plain) { create(:type, name: "Plain") }

    current_user { create(:user, member_with_permissions: { project => %i[view_project] }) }

    before do
      create(:project_type, project:, type: plain)
      render_inline(described_class.new(project:))
    end

    it "shows no blank slate for it" do
      expect(page).to have_no_css(".blankslate")
      expect(page).to have_no_css("[data-test-selector='op-empty-state']")
    end

    it "still shows the type" do
      expect(page).to have_text("Plain")
    end
  end

  describe "when the project uses the type's own configuration" do
    current_user { create(:user, member_with_permissions: { project => %i[view_project] }) }

    before { render_inline(component) }

    it "states so on the header, which is that configuration's own row" do
      expect(group(bug.default_variant)).to have_text("Base type used in this project")
    end

    it "checks it off, so the reader finds it without reading" do
      expect(group(bug.default_variant)).to have_css(".octicon-check-circle-fill")
    end

    # A statement of fact rather than something to notice: the header's title slot would
    # otherwise lend it the type name's weight.
    it "does not emphasise it" do
      expect(group(bug.default_variant)).to have_css(".text-normal", text: "Base type used in this project")
    end

    # Nothing below the header is in use, so the group has nothing the reader must see.
    it "leaves the group closed" do
      expect(group(bug.default_variant)).to have_css(".CollapsibleHeader--collapsed")
    end

    it "says nothing about a variant being in use" do
      expect(page).to have_no_text("Variant in this project")
    end
  end

  describe "when the project uses a named variant" do
    current_user { create(:user, member_with_permissions: { project => %i[view_project] }) }

    before do
      use_variant(global)
      render_inline(component)
    end

    it "states so on that variant's row" do
      expect(row(global)).to have_text("Variant in this project")
    end

    it "checks that row off" do
      expect(row(global)).to have_css(".octicon-check-circle-fill")
    end

    it "says nothing of the sort on the variants the project is not using" do
      expect(row(ours)).to have_no_text("Variant in this project")
    end

    # The row saying so is inside the group, so the group has to be open for it to be read.
    it "opens the group" do
      expect(group(global)).to have_no_css(".CollapsibleHeader--collapsed")
    end

    it "leaves the header naming the type alone" do
      expect(group(global)).to have_no_text("Base type used in this project")
    end
  end

  describe "switching which variant the project uses" do
    current_user do
      create(:user, member_with_permissions: { project => %i[view_project manage_project_variants] })
    end

    context "when the project uses the type's own configuration" do
      before { render_inline(component) }

      # The reader has already chosen on the row, so the dialog opens on that variant rather than
      # asking them to find it again in a select.
      it "offers a row's variant for use, with the dialog set to it" do
        expect(page).to have_link(
          "Use in this project",
          href: new_project_settings_work_packages_type_switch_path(project, bug, target_id: global.id)
        )
      end

      it "offers the project's own variant for use too" do
        expect(page).to have_link(
          "Use in this project",
          href: new_project_settings_work_packages_type_switch_path(project, bug, target_id: ours.id)
        )
      end
    end

    context "when the project already uses one of them" do
      before do
        use_variant(global)
        render_inline(described_class.new(project:))
      end

      it "offers nothing to the row already in use" do
        expect(row(global)).to have_no_link("Use in this project")
      end

      it "still offers the others" do
        expect(row(ours)).to have_link("Use in this project")
      end
    end
  end

  # The header stands for the type's own configuration, the way each row below it stands for a
  # variant. Its action therefore puts that configuration to use, named and preselected exactly
  # as a row's is.
  describe "the type's own menu" do
    current_user do
      create(:user, member_with_permissions: { project => %i[view_project manage_types manage_project_variants] })
    end

    context "when the project uses a named variant" do
      before do
        use_variant(ours)
        render_inline(described_class.new(project:))
      end

      it "offers the type's own configuration for use, already chosen" do
        expect(header_of(ours)).to have_link("Use in this project", href: switch_path(bug.default_variant))
      end

      it "marks it with the same check the rows carry" do
        expect(header_of(ours)).to have_css(".octicon-check-circle")
      end
    end

    context "when the project already uses the type's own configuration" do
      before { render_inline(component) }

      it "offers nothing to put to use" do
        expect(header_of(bug.default_variant)).to have_no_link("Use in this project")
      end

      # Taking the type out of the project is not of a kind with the rest of the menu.
      it "still sets taking the type out of the project apart" do
        expect(header_of(bug.default_variant)).to have_css(".ActionList-sectionDivider")
      end
    end
  end

  # Choosing the types the project uses is not choosing which variant of one it runs on.
  describe "a member who may only choose the project's types" do
    current_user { create(:user, member_with_permissions: { project => %i[view_project manage_types] }) }

    before { render_inline(component) }

    it "offers no way to switch from the type's menu" do
      expect(page).to have_no_link("Use in this project")
    end

    it "offers no way to switch from a variant's row" do
      expect(row(global)).to have_no_css("action-menu")
    end

    it "still offers to take the type out of the project" do
      expect(page).to have_button("Remove from project", visible: :all)
    end

    # Nothing precedes it in the menu, so there is nothing to set it apart from.
    it "renders no divider" do
      expect(header_of(bug.default_variant)).to have_no_css(".ActionList-sectionDivider")
    end
  end

  # Applying one's own variant would be a trap if it could not be undone.
  describe "an author of the project's variants, once the project uses their variant" do
    current_user do
      create(:user, member_with_permissions: { project => %i[view_project manage_project_variants] })
    end

    before do
      use_variant(ours)
      render_inline(described_class.new(project:))
    end

    it "offers the type's own configuration for use, so the variant can be taken back off" do
      expect(page).to have_link("Use in this project", href: switch_path(bug.default_variant))
    end
  end

  context "when the member may not manage them" do
    current_user { create(:user, member_with_permissions: { project => %i[view_project] }) }

    before { render_inline(component) }

    it "still lists the variants the project may use" do
      expect(page).to have_text("Internal review")
      expect(page).to have_text("Mobile")
    end

    it "offers no way to add one" do
      expect(page).to have_no_link("Add a project-specific variant")
    end

    it "offers no way to configure one" do
      expect(page).to have_no_link("Edit")
    end

    it "offers no way to switch to one" do
      expect(page).to have_no_link("Use in this project")
    end

    it "leaves even its own variant's name unlinked" do
      expect(page).to have_text("Internal review")
      expect(page).to have_no_link("Internal review")
    end

    # An empty kebab is a promise of something to do, on every row of every type.
    it "renders no action menu on a row it can do nothing with" do
      expect(row(ours)).to have_no_css("action-menu")
    end
  end
end
