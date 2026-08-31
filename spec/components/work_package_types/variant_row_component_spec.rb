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

  subject(:rendered_component) { render_inline(described_class.new(variant:)) }

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

  # A slot rather than a string, because one list says "Created in <project>" with the project
  # linked, which no string can carry.
  it "renders the caption its caller gives it" do
    rendered = render_inline(described_class.new(variant:)) do |row|
      row.with_caption { I18n.t("types.index.variant_label") }
    end

    expect(rendered).to have_text(I18n.t("types.index.variant_label"))
  end

  it "says nothing about new projects while the variant is not the one they start with" do
    expect(rendered_component).to have_no_text(I18n.t("types.index.enabled_in_new_projects"))
  end

  # What a list says about the variant's state here. Not a label: one list says it with a green
  # check and coloured words, which a Label cannot carry.
  it "renders the state its caller gives it" do
    rendered = render_inline(described_class.new(variant:)) do |row|
      row.with_state { "Variant in this project" }
    end

    expect(rendered).to have_text("Variant in this project")
  end

  it "says nothing of its own about ownership or new projects" do
    expect(rendered_component).to have_no_css(".Label")
  end

  # Right-aligned, for status rather than an affordance.
  it "sets a status label apart from the rest" do
    rendered = render_inline(described_class.new(variant:)) do |row|
      row.with_status_label { "Active in new projects" }
    end

    expect(rendered).to have_css(".Label", text: "Active in new projects")
  end

  it "renders the name as plain text when it is not linked" do
    rendered = render_inline(described_class.new(variant:, linked: false))

    expect(rendered).to have_text("Hardware")
    expect(rendered).to have_no_link("Hardware")
  end
end
