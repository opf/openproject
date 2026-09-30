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

RSpec.describe WorkPackageTypes::Types::GroupedListComponent, type: :component do
  include Rails.application.routes.url_helpers

  current_user { create(:admin) }

  describe "a variant a project owns" do
    shared_let(:owning_project) { create(:project, name: "Apollo") }
    shared_let(:root_type) { create(:type, name: "Bug") }
    shared_let(:owned) do
      create(:project_owned_type_variant, type: root_type, project: owning_project, variant_name: "Internal")
    end
    shared_let(:global) { create(:type_variant, type: root_type, variant_name: "Mobile") }

    subject(:rendered_component) do
      with_request_url "/types" do
        render_inline(described_class.new(types: Type.where(id: root_type.id).page(1).per_page(10)))
      end
    end

    it "does not list it" do
      expect(rendered_component).to have_no_text("Internal")
    end

    it "sets the type's name in the same weight as its variants" do
      expect(rendered_component).to have_css(".Box-header a.text-bold", text: "Bug")
    end

    it "still lists the variants every project may use" do
      expect(rendered_component).to have_text("Mobile")
    end

    it "counts it, and links the count to the type's variants tab" do
      expect(rendered_component).to have_link("1 project-specific variant",
                                              href: type_variants_path(type_id: root_type.id))
    end

    it "leads with the count rather than an icon", :aggregate_failures do
      row = "[data-test-selector='type-#{root_type.id}-project-variants']"

      expect(rendered_component).to have_css(row)
      expect(rendered_component).to have_no_css("#{row} svg")
      expect(rendered_component).to have_no_css("#{row}.color-fg-muted")
    end

    it "counts them in a row above the add action", :aggregate_failures do
      count_link = "a[href='#{type_variants_path(type_id: root_type.id)}']"
      add_link = "a[href='#{new_creation_wizard_type_variants_path(type_id: root_type.id, back_url: types_path)}']"

      expect(rendered_component).to have_css(".Box-row #{count_link}")
      expect(rendered_component).to have_no_css(".Box-footer #{count_link}")
      expect(rendered_component).to have_css(".Box-row:last-of-type #{add_link}")
    end

    it "names the type it adds to" do
      expect(rendered_component).to have_link("Add a variant to Bug")
    end

    it "counts only the variants projects own" do
      expect(rendered_component).to have_no_text("2 project-specific variants")
    end

    it "counts both in a badge on the header" do
      expect(rendered_component).to have_css(".Box-header .Counter", text: "2")
    end

    context "when the type has no variant at all" do
      shared_let(:root_type) { create(:type, name: "Plain") }
      shared_let(:owned) { nil }
      shared_let(:global) { nil }

      # visible: :all, because Primer hides a zero counter by itself: a visible-only assertion
      # would hold whether or not the count is left out.
      it "shows no badge" do
        expect(rendered_component).to have_no_css(".Box-header .Counter", visible: :all)
      end
    end

    it "no longer spells the count out" do
      expect(rendered_component).to have_no_text("2 variants")
    end
  end

  describe "a variant-less root" do
    let(:root_type) { create(:type, name: "Task") }

    subject(:rendered_component) do
      with_request_url "/types" do
        render_inline(described_class.new(types: Type.where(id: root_type.id).page(1).per_page(10)))
      end
    end

    it "renders the group header but no generic empty state", :aggregate_failures do
      expect(rendered_component).to have_css("h4.Box-title", text: root_type.name)
      expect(rendered_component).to have_no_css("[data-empty-list-item]")
      expect(rendered_component).to have_no_css(".blankslate")
    end
  end

  describe "the label marking what new projects start with" do
    let(:root_type) { create(:type, name: "Task") }
    let!(:variant) { create(:type_variant, type: root_type, variant_name: "Hardware") }
    let(:label_text) { I18n.t("types.index.enabled_in_new_projects") }

    subject(:rendered_component) do
      with_request_url "/types" do
        render_inline(described_class.new(types: Type.where(id: root_type.id).page(1).per_page(10),
                                          expanded_type_id: root_type.id))
      end
    end

    context "when no variant of the type carries the flag" do
      it "renders nowhere" do
        expect(rendered_component).to have_no_css(".Label", text: label_text)
      end
    end

    context "when the base variant carries it" do
      before { root_type.default_variant.update!(enabled_in_new_projects: true) }

      it "marks the group header only: the base variant has no row of its own", :aggregate_failures do
        expect(rendered_component).to have_css(".Box-header .Label", text: label_text)
        expect(rendered_component).to have_no_css(".Box-row .Label", text: label_text)
      end
    end

    context "when a named variant carries it" do
      before { variant.update!(enabled_in_new_projects: true) }

      it "marks the variant's own row and leaves the header alone", :aggregate_failures do
        expect(rendered_component).to have_css(".Box-row .Label", text: label_text)
        expect(rendered_component).to have_no_css(".Box-header .Label")
      end
    end
  end

  describe "sortable groups", with_settings: { per_page_options: "2,100" } do
    let!(:types) { %w[A B C D E].map { |name| create(:type, name:) } }
    let(:page_two) { Type.order(:position).page(2).per_page(2) }
    let(:expanded) { page_two.first }
    let!(:variant) { create(:type_variant, type: expanded, variant_name: "Variant") }
    let(:wrapper) { described_class.wrapper_key }

    subject(:rendered_component) do
      with_request_url "/types?page=2&per_page=2" do
        render_inline(described_class.new(types: page_two, expanded_type_id: expanded.id))
      end
    end

    it_behaves_like "a sortable-lists list", list_type: "type", name: "Types"

    it "wires the component wrapper as the sortable-lists root", :aggregate_failures do
      expect(rendered_component).to have_element(id: wrapper) do |root|
        expect(root["data-controller"]).to eq("sortable-lists")
        expect(root["data-sortable-lists-sortable-lists--list-outlet"])
          .to eq("##{wrapper} [data-controller~='sortable-lists--list']")
        expect(root["data-sortable-lists-sortable-lists--item-outlet"])
          .to eq("##{wrapper} [data-controller~='sortable-lists--item']")
      end
    end

    it "lists the types of the page by name" do
      expect(rendered_component).to have_selector(:list, "Types") do |list|
        expect(list.all(:heading).map { it.text.squish }).to eq(page_two.map(&:name))
      end
    end

    it "registers type groups, not variant rows, as sortable items", :aggregate_failures do
      expect(rendered_component)
        .to have_element(role: "listitem", "data-controller": "sortable-lists--item", count: 2)
      expect(rendered_component).to have_no_element(:li, "data-controller": "sortable-lists--item")
    end

    it "gives each type group a single drag handle as its item handle" do
      expect(rendered_component).to have_button(accessible_name: "Drag to reorder", count: 2) do |handle|
        handle["data-sortable-lists--item-target"] == "handle"
      end
    end

    it "carries page context through the drop URL" do
      expected = drop_type_path("__id__", page: 2, per_page: 2, expand: expanded.id).sub("__id__", "{id}")

      expect(rendered_component).to have_element(id: wrapper) do |root|
        expect(root["data-sortable-lists-move-url-template-value"]).to eq(expected)
      end
    end

    it "carries page context through the pagination links" do
      expect(rendered_component).to have_link("1", href: types_path(page: 1, per_page: 2, expand: expanded.id))
    end
  end

  describe "a lone type" do
    let!(:lone) { create(:type, name: "Only") }

    subject(:rendered_component) do
      with_request_url "/types" do
        render_inline(described_class.new(types: Type.page(1).per_page(10)))
      end
    end

    it "fixes a lone type in place without a drag handle", :aggregate_failures do
      expect(Type.count).to eq(1)
      expect(rendered_component)
        .to have_element(role: "listitem", "data-sortable-lists--item-mobility-value": "fixed", count: 1)
      expect(rendered_component).to have_no_button(accessible_name: "Drag to reorder")
    end
  end
end
