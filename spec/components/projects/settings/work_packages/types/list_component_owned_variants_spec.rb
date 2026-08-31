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

    it "marks which of them is the project's own" do
      expect(page).to have_text("Only available in this project")
    end

    # Which variant the project is using is what a reader is looking for, so that is the label
    # the accent belongs to. Ownership is a statement of fact about the row it sits on.
    it "accents the variant in use rather than the one it owns" do
      expect(page).to have_css(".Label--accent", text: "In use")
      expect(page).to have_no_css(".Label--accent", text: "Only available in this project")
    end

    it "offers to add one" do
      expect(page).to have_link(
        "Add a variant for this project",
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

    it "offers to delete the one it owns" do
      expect(page).to have_css(
        "form[action='#{type_variant_path(in_project_id: project, type_id: bug.id, id: ours.id)}']",
        visible: :all
      )
    end

    # A global variant belongs to every project, so no single one may edit or remove it.
    it "offers no action on a global variant" do
      expect(page).to have_no_link(
        "Edit",
        href: edit_type_details_path(in_project_id: project, type_id: bug.id, variant_id: global.id)
      )
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

  # The header row is the type's own configuration. Which of the two is in use is said the same
  # way throughout: the row that is in use carries the label, named variant or not.
  describe "the header when the type's own configuration is in use" do
    current_user { create(:user, member_with_permissions: { project => %i[view_project] }) }

    before { render_inline(component) }

    it "marks it in use rather than naming it" do
      expect(page).to have_text("In use")
    end

    it "names no variant" do
      expect(page).to have_no_text("Variant:")
    end

    # Nothing is nested under the header for it, so the label there is the only thing saying so.
    it "puts the label on the header, not on a variant row" do
      expect(page).to have_css(".Label", text: "In use", count: 1)
    end
  end

  describe "the header when a named variant is in use" do
    current_user { create(:user, member_with_permissions: { project => %i[view_project] }) }

    before do
      project.project_types.find_by(type: bug).update!(variant: global)
      render_inline(component)
    end

    it "names that variant" do
      expect(page).to have_text(/Variant:\s*Mobile/)
    end

    it "leaves the in-use label to that variant's own row" do
      expect(page).to have_text("In use")
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
      expect(page).to have_no_link("Add a variant for this project")
    end

    it "offers no way to configure one" do
      expect(page).to have_no_link("Edit")
    end

    it "leaves even its own variant's name unlinked" do
      expect(page).to have_text("Internal review")
      expect(page).to have_no_link("Internal review")
    end
  end
end
