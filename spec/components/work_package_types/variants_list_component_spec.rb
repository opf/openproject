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

  subject(:rendered_component) { render_inline(described_class.new(type:)) }

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

    it "loads each variant's action menu from the variants controller" do
      [alfa, zeta].each do |variant|
        expect(rendered_component)
          .to have_css("[src='#{menu_type_variant_path(type_id: type.id, id: variant.id)}']", visible: :all)
      end
    end

    it "offers to add another variant from the header" do
      expect(rendered_component)
        .to have_link(I18n.t("types.index.add_variant_action"), href: new_creation_wizard_types_path(type_id: type.id))
    end

    it "marks the variant new projects start with" do
      alfa.update!(enabled_in_new_projects: true)

      expect(rendered_component).to have_text(I18n.t("types.index.enabled_in_new_projects"))
    end
  end

  context "without named variants" do
    it "renders a blankslate offering to add one" do
      expect(rendered_component).to have_text(I18n.t("types.edit.variants.blankslate.title"))
      expect(rendered_component)
        .to have_link(I18n.t("types.index.add_variant_action"), href: new_creation_wizard_types_path(type_id: type.id))
    end
  end
end
