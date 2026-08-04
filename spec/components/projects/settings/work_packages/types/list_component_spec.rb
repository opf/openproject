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

  context "when a switch is running in the background" do
    shared_let(:blueprint) { create(:type, name: "Blueprint", parent: epic) }

    # A second family with variants of its own, so the effect of a switch on the
    # rows that are not switching is visible.
    shared_let(:feature) { create(:type, name: "Feature").tap { |type| type.update_column(:position, 3) } }
    shared_let(:research) { create(:type, name: "Research", parent: feature) }

    subject(:component) { described_class.new(project:, pending_switch:) }

    let(:project) { create(:project, types: [design, research]) }
    let(:pending_switch) do
      instance_double(Projects::Types::SwitchStatus, source_id: design.id, target: blueprint)
    end

    before { render_inline(component) }

    # Its own name, not the composite one: the parent already labels the row.
    it "says where the switching family is heading" do
      expect(page).to have_text("Switching to variant: Blueprint", normalize_ws: true)
    end

    context "when the target is the family parent rather than a variant" do
      let(:pending_switch) do
        instance_double(Projects::Types::SwitchStatus, source_id: design.id, target: epic)
      end

      it "drops the word variant, because the project will be left on none" do
        expect(page).to have_text("Switching to: Epic", normalize_ws: true)
      end
    end

    it "polls, so the row settles without the user reloading" do
      expect(page).to have_css("[data-controller='poll-for-changes']")
    end

    it "offers no actions on the switching row" do
      expect(switching_row).to have_no_button("Remove from project", visible: :all)
    end

    # The service takes an advisory lock on the project, so a second switch would
    # queue behind the first. Disabling says so; hiding used to leave families
    # nobody is switching looking broken.
    it "keeps the switch action on the other family, disabled and explained" do
      expect(other_family_row).to have_text("Switch variant")
      expect(other_family_row).to have_text("Another variant switch is in progress.")
      expect(other_family_row).to have_no_css(
        "a[href='#{new_project_settings_work_packages_type_switch_path(project, research)}']",
        visible: :all
      )
    end

    def switching_row
      page.find("[data-test-selector='project-types-row-#{design.id}']", visible: :all)
    end

    def other_family_row
      page.find("[data-test-selector='project-types-row-#{research.id}']", visible: :all)
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
end
