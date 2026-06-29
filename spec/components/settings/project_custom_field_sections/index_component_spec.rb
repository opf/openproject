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

RSpec.describe Settings::ProjectCustomFieldSections::IndexComponent, type: :component do
  let(:section) { create(:project_custom_field_section, name: "Test Section") }

  subject(:rendered_component) do
    with_request_url "/admin/settings/project_custom_fields" do
      render_inline(described_class.new(project_custom_field_sections: [section]))
    end
  end

  before do
    allow(section).to receive(:custom_fields).and_return([])
  end

  it "mounts only sortable-lists (not generic-drag-and-drop) on the root wrapper" do
    expect(rendered_component)
      .to have_css("[data-controller~='sortable-lists']")
    expect(rendered_component)
      .to have_no_css("[data-controller~='generic-drag-and-drop']")
  end

  it "sets sortable-lists position mode to absolute" do
    expect(rendered_component)
      .to have_css("[data-sortable-lists-position-mode-value='absolute']")
  end

  it "sets the custom_field move-url-template to a literal {id} URL (not URL-encoded)" do
    expect(rendered_component)
      .to have_css("[data-sortable-lists-move-url-templates-value*='project_custom_fields/{id}/drop']")
  end

  it "sets the section move-url-template to a literal {id} URL (not URL-encoded)" do
    expect(rendered_component)
      .to have_css("[data-sortable-lists-move-url-templates-value*='project_custom_field_sections/{id}/drop']")
  end

  it "does not URL-encode the {id} placeholder in move-url-templates" do
    node = rendered_component.at_css("[data-sortable-lists-move-url-templates-value]")
    expect(node["data-sortable-lists-move-url-templates-value"]).not_to include("%7B")
    expect(node["data-sortable-lists-move-url-templates-value"]).not_to include("%7D")
  end

  it "renders the sections container as a <ul> carrying the sortable-lists--list controller" do
    expect(rendered_component)
      .to have_css("ul[data-controller~='sortable-lists--list']")
  end

  it "sets the sections list type-value to section" do
    expect(rendered_component)
      .to have_css("ul[data-sortable-lists--list-type-value='section']")
  end

  it "sets the sections list accepted-types-value to the section JSON array" do
    expect(rendered_component)
      .to have_css("ul[data-sortable-lists--list-accepted-types-value='[\"section\"]']")
  end

  it "does not set an id-value on the sections list (global single list)" do
    node = rendered_component.at_css(
      "ul[data-controller~='sortable-lists--list'][data-sortable-lists--list-type-value='section']"
    )
    expect(node["data-sortable-lists--list-id-value"]).to be_nil
  end

  it "renders each section as an <li> carrying the sortable-lists--item controller" do
    expect(rendered_component)
      .to have_css("li[data-controller~='sortable-lists--item']")
  end

  it "sets the section item id-value to the section id" do
    expect(rendered_component)
      .to have_css("li[data-sortable-lists--item-id-value='#{section.id}']")
  end

  it "sets the section item type-value to section" do
    expect(rendered_component)
      .to have_css("li[data-sortable-lists--item-type-value='section']")
  end

  it "renders section <li> rows as direct children of the sections <ul>" do
    node = rendered_component.at_css("ul[data-sortable-lists--list-type-value='section']")
    direct_li_items = node.css("> li[data-controller~='sortable-lists--item']")
    expect(direct_li_items.length).to eq(1)
  end
end
