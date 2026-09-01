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

    it "still lists the variants every project may use" do
      expect(rendered_component).to have_text("Mobile")
    end

    it "counts it, and links the count to the type's variants tab" do
      expect(rendered_component).to have_link("1 variant owned by a project",
                                              href: type_variants_path(type_id: root_type.id))
    end

    it "counts it in the footer rather than in a row", :aggregate_failures do
      count_link = "a[href='#{type_variants_path(type_id: root_type.id)}']"

      expect(rendered_component).to have_css(".Box-footer #{count_link}")
      expect(rendered_component).to have_no_css(".Box-row #{count_link}")
    end

    # The last row of the list, below the variants and above the footer.
    it "adds a variant from a row, not from the group header", :aggregate_failures do
      add_link = "a[href='#{new_creation_wizard_types_path(type_id: root_type.id, back_url: types_path)}']"

      expect(rendered_component).to have_css(".Box-row #{add_link}")
      expect(rendered_component).to have_no_css(".Box-header #{add_link}")
      expect(rendered_component).to have_no_css(".Box-footer #{add_link}")
    end

    it "names the type it adds to" do
      expect(rendered_component).to have_link("Add variant to Bug")
    end

    it "counts only the variants projects own" do
      expect(rendered_component).to have_no_text("2 variants owned by projects")
    end

    # The header counts every named variant of the type, listed or not, so it is the whole
    # picture: one listed here plus the one the project owns.
    it "counts both in the header" do
      expect(rendered_component).to have_css(".Box-header", text: "2 variants")
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
    let(:variant_label_text) do
      I18n.t("types.index.variant_enabled_in_new_projects", name: variant.variant_name)
    end

    subject(:rendered_component) do
      with_request_url "/types" do
        render_inline(described_class.new(types: Type.where(id: root_type.id).page(1).per_page(10),
                                          expanded_type_id: root_type.id))
      end
    end

    context "when no variant of the type carries the flag" do
      it "renders nowhere", :aggregate_failures do
        expect(rendered_component).to have_no_css(".Label", text: label_text)
        expect(rendered_component).to have_no_css(".Label", text: variant_label_text)
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

      it "names the variant in the group header, which stays visible when collapsed" do
        expect(rendered_component).to have_css(".Box-header .Label", text: variant_label_text)
      end

      it "marks the variant's own row too" do
        expect(rendered_component).to have_css(".Box-row .Label", text: label_text)
      end
    end
  end
end
