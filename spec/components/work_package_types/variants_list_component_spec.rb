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

RSpec.describe WorkPackageTypes::VariantsListComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type, name: "Bug") }

  subject(:rendered_component) { render_inline(described_class.new(type:, query:)) }

  let(:query) { nil }

  # The wizard is reachable from the types index too, so it has to be told to come back here.
  let(:add_variant_href) do
    new_creation_wizard_types_path(type_id: type.id, back_url: type_variants_path(type_id: type.id))
  end

  # The types index counts these rather than listing them, so this tab is where an administrator
  # sees whose they are.
  context "with a variant a project owns" do
    shared_let(:owning_project) { create(:project, name: "Apollo") }
    shared_let(:owned) do
      create(:project_owned_type_variant, type:, project: owning_project, variant_name: "Internal")
    end

    it "attributes it to the project owning it" do
      expect(rendered_component).to have_text("Owned by Apollo")
    end

    it "links it into the project owning it" do
      expect(rendered_component)
        .to have_link("Internal",
                      href: edit_type_details_path(in_project_id: owning_project,
                                                   type_id: type.id, variant_id: owned.id))
    end
  end

  context "with named variants" do
    let!(:zeta) { create(:type_variant, type:, variant_name: "Zeta") }
    let!(:alfa) { create(:type_variant, type:, variant_name: "Alfa") }

    it "links every named variant to its settings page" do
      expect(rendered_component).to have_link("Alfa", href: edit_type_details_path(type_id: type.id, variant_id: alfa.id))
      expect(rendered_component).to have_link("Zeta", href: edit_type_details_path(type_id: type.id, variant_id: zeta.id))
    end

    it "lists them in display order" do
      names = rendered_component.css("[data-test-selector^='type-variant-'] a").map { it.text.strip }

      expect(names).to eq(%w[Alfa Zeta])
    end

    it "leaves out the base variant: that is the type itself" do
      expect(rendered_component).to have_no_link(type.name)
      expect(rendered_component.css("[data-test-selector^='type-variant-']").size).to eq(2)
    end

    it "loads each variant's action menu, telling it to come back to this tab" do
      [alfa, zeta].each do |variant|
        src = menu_type_variant_path(type_id: type.id, id: variant.id,
                                     back_url: type_variants_path(type_id: type.id))

        expect(rendered_component).to have_css("[src='#{src}']", visible: :all)
      end
    end

    it "offers to add another variant from the sub header" do
      expect(rendered_component)
        .to have_link(I18n.t("types.index.variant_label"), href: add_variant_href)
    end

    it "submits the filter input to the list's turbo frame" do
      expect(rendered_component).to have_field(I18n.t("types.edit.variants.filter"))
      expect(rendered_component)
        .to have_css("form[action='#{type_variants_path(type_id: type.id)}'][data-turbo-frame='#{described_class::FRAME_ID}']")
      expect(rendered_component).to have_css("turbo-frame##{described_class::FRAME_ID}", visible: :all)
    end

    it "marks the variant new projects start with" do
      alfa.update!(enabled_in_new_projects: true)

      expect(rendered_component).to have_text(I18n.t("types.index.enabled_in_new_projects"))
    end

    context "with a query matching one of them" do
      let(:query) { "alf" }

      it "lists only the matches and keeps the query in the input" do
        expect(rendered_component).to have_link("Alfa")
        expect(rendered_component).to have_no_link("Zeta")
        expect(rendered_component).to have_field(I18n.t("types.edit.variants.filter"), with: "alf")
      end
    end

    context "with a query matching none of them" do
      let(:query) { "nothing like it" }

      it "keeps the filter around and says so, rather than falling back to the blankslate" do
        expect(rendered_component).to have_text(I18n.t("types.edit.variants.filter_no_results"))
        expect(rendered_component).to have_field(I18n.t("types.edit.variants.filter"))
        expect(rendered_component).to have_no_css("[data-test-selector='type-variants-blankslate']")
      end
    end
  end

  context "without named variants" do
    it "renders a blankslate offering to add one, instead of an empty list" do
      expect(rendered_component).to have_css("[data-test-selector='type-variants-blankslate']")
      expect(rendered_component).to have_no_css("[data-test-selector='type-variants']")
      expect(rendered_component).to have_text(I18n.t("types.edit.variants.blankslate.title"))
      expect(rendered_component)
        .to have_css("[data-test-selector='type-variants-blankslate'] p br")
      expect(rendered_component)
        .to have_link(I18n.t("types.index.add_variant_action"), href: add_variant_href)
    end
  end
end
