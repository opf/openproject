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

RSpec.describe WorkPackageTypes::VariantRowComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Hardware") }

  subject(:rendered_component) { render_inline(described_class.new(variant:, caption:)) }

  let(:caption) { nil }

  it "links the variant to its settings page" do
    expect(rendered_component)
      .to have_link("Hardware", href: edit_type_details_path(type_id: type.id, variant_id: variant.id))
  end

  it "names no project for a variant every project may use" do
    expect(rendered_component).to have_no_link("Hardware", href: /in-project/)
  end

  it "leaves out the caption unless one is given" do
    expect(rendered_component).to have_no_text(I18n.t("types.index.variant_label"))
  end

  it "says nothing about new projects while the variant is not the one they start with" do
    expect(rendered_component).to have_no_text(I18n.t("types.index.enabled_in_new_projects"))
  end

  context "with a caption" do
    let(:caption) { I18n.t("types.index.variant_label") }

    it "renders it next to the name" do
      expect(rendered_component).to have_text(caption)
    end
  end

  it "says nothing about an owner while every project may use the variant" do
    expect(rendered_component).to have_no_text("Owned by")
  end

  context "when a project owns the variant" do
    shared_let(:owning_project) { create(:project, name: "Apollo") }
    shared_let(:owned) do
      create(:project_owned_type_variant, type:, project: owning_project, variant_name: "Internal")
    end

    subject(:rendered_component) { render_inline(described_class.new(variant: owned, caption:)) }

    it "attributes the row to the project owning it" do
      expect(rendered_component).to have_text("Owned by Apollo")
    end

    # Reached from administration's variants tab, where the row is listed. The project's copy of
    # the screen is the coherent one: it is the only place the variant is used, and the tabs there
    # leave out the projects a type is used in.
    it "links into the project owning it" do
      expect(rendered_component)
        .to have_link("Internal",
                      href: edit_type_details_path(in_project_id: owning_project,
                                                   type_id: type.id, variant_id: owned.id))
    end

    # Whose it is, is a statement of fact about the row. The accent is reserved for what a
    # reader is looking for, which is which variant is in use.
    it "does not accent the attribution" do
      expect(rendered_component).to have_css(".Label", text: "Owned by Apollo")
      expect(rendered_component).to have_no_css(".Label--accent", text: "Owned by Apollo")
    end
  end

  context "when new projects start with this variant" do
    before { variant.update!(enabled_in_new_projects: true) }

    it "labels the row" do
      expect(rendered_component).to have_text(I18n.t("types.index.enabled_in_new_projects"))
    end
  end
end
