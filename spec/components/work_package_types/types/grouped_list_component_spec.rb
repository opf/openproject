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

  # An administrator sees every project's variants together, so an owned one has to say whose it
  # is; otherwise it is indistinguishable from a variant every project may use.
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

    # The index is the list of variants every project may use. A project's own belong to that
    # project, and are reached from the type's variants tab instead.
    it "does not list it" do
      expect(rendered_component).to have_no_text("Internal")
    end

    # As bold as the variant names below it: the type heads the group, it does not caption it.
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

    # A plain link, like the variant names above it: it leads somewhere the reader may go, and it
    # is not an affordance of the kind the add action below it is.
    it "leads with the count rather than an icon", :aggregate_failures do
      row = "[data-test-selector='type-#{root_type.id}-project-variants']"

      expect(rendered_component).to have_css(row)
      expect(rendered_component).to have_no_css("#{row} svg")
      expect(rendered_component).to have_no_css("#{row}.color-fg-muted")
    end

    # The count summarises variants this list does not show; the add action creates one that it
    # will, and closes the group.
    it "counts them in a row above the add action", :aggregate_failures do
      count_link = "a[href='#{type_variants_path(type_id: root_type.id)}']"
      add_link = "a[href='#{new_creation_wizard_types_path(type_id: root_type.id, back_url: types_path)}']"

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

    # The badge counts every named variant of the type, listed here or not: one on this list plus
    # the one the project owns.
    it "counts both in a badge on the header" do
      expect(rendered_component).to have_css(".Box-header .Counter", text: "2")
    end

    # Asserted on the markup rather than on what shows: Primer hides a zero counter by itself, so
    # a visible-only assertion would hold without the count ever being left out.
    context "when the type has no variant at all" do
      shared_let(:root_type) { create(:type, name: "Plain") }
      shared_let(:owned) { nil }
      shared_let(:global) { nil }

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

      # Said on the variant's own row, and nowhere else.
      it "marks the variant's own row and leaves the header alone", :aggregate_failures do
        expect(rendered_component).to have_css(".Box-row .Label", text: label_text)
        expect(rendered_component).to have_no_css(".Box-header .Label")
      end
    end
  end
end
