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

RSpec.describe Settings::ProjectCustomFieldSections::ShowComponent, type: :component do
  let(:section) { create(:project_custom_field_section, name: "Test Section") }
  let(:custom_fields) { [] }

  subject(:rendered_component) do
    with_request_url "/admin/settings/project_custom_fields" do
      render_inline(described_class.new(project_custom_field_section: section))
    end
  end

  before do
    allow(section).to receive(:custom_fields).and_return(custom_fields)
  end

  shared_examples_for "rendering the rich section header" do
    it "renders the section container" do
      expect(rendered_component)
        .to have_css("[data-test-selector='project-custom-field-section-container-#{section.id}']")
    end

    it "renders a Box header" do
      expect(rendered_component).to have_css(".Box-header")
    end

    it "renders the drag handle in the header" do
      expect(rendered_component).to have_css(".Box-header .handle")
    end

    it "wires the header drag handle as the sortable-lists--item handle target" do
      expect(rendered_component)
        .to have_css(".Box-header .handle[data-sortable-lists--item-target~='handle']")
    end

    it "renders the display-representation action-menu in the header" do
      expect(rendered_component)
        .to have_css("action-menu[data-test-selector='section-position-selector']")
    end

    it "renders the section kebab action-menu in the header" do
      expect(rendered_component)
        .to have_css("action-menu[data-test-selector='project-custom-field-section-action-menu']")
    end
  end

  context "with no custom fields (empty section)" do
    let(:custom_fields) { [] }

    include_examples "rendering the rich section header"

    it "renders the field list as a BorderBoxListComponent Box" do
      expect(rendered_component).to have_css(".Box .op-border-box-list")
    end

    it "renders the empty-state blankslate inside the list" do
      expect(rendered_component).to have_css(".op-border-box-list .blankslate")
    end

    it "renders the empty-state heading with the expected text" do
      expect(rendered_component).to have_heading(
        I18n.t("settings.project_attributes.label_no_project_custom_fields"),
        class: "blankslate-heading"
      )
    end

    it "renders the new-attribute action-menu" do
      expect(rendered_component)
        .to have_css("[data-test-selector='new-project-custom-field-in-section-button']")
    end
  end

  context "with custom fields" do
    let(:field_one) { build_stubbed(:project_custom_field, name: "Alpha Field") }
    let(:field_two) { build_stubbed(:project_custom_field, name: "Beta Field") }
    let(:custom_fields) { [field_one, field_two] }

    before do
      allow(field_one).to receive_messages(
        project_custom_field_project_mappings: [],
        field_format_calculated_value?: false
      )
      allow(field_two).to receive_messages(
        project_custom_field_project_mappings: [],
        field_format_calculated_value?: false
      )
    end

    include_examples "rendering the rich section header"

    it "renders the field list as a BorderBoxListComponent Box" do
      expect(rendered_component).to have_css(".op-border-box-list")
    end

    it "renders field rows as list items inside the BorderBoxList" do
      expect(rendered_component).to have_css(".op-border-box-list .Box-row", count: 2)
    end

    it "renders a row for each custom field by name" do
      expect(rendered_component).to have_css("li", text: "Alpha Field")
      expect(rendered_component).to have_css("li", text: "Beta Field")
    end

    it "renders each row with a kebab action-menu" do
      expect(rendered_component)
        .to have_css("[data-test-selector='project-custom-field-action-menu']", count: 2)
    end

    it "does not render the new-attribute action-menu" do
      expect(rendered_component)
        .to have_no_css("[data-test-selector='new-project-custom-field-in-section-button']")
    end

    it "wires the field list as a sortable-lists--list controller" do
      expect(rendered_component)
        .to have_css(".op-border-box-list[data-controller~='sortable-lists--list']")
    end

    it "sets the list type value to custom_field" do
      expect(rendered_component)
        .to have_css(".op-border-box-list[data-sortable-lists--list-type-value='custom_field']")
    end

    it "sets the list accepted-types value to the custom_field JSON array" do
      expect(rendered_component)
        .to have_css(".op-border-box-list[data-sortable-lists--list-accepted-types-value='[\"custom_field\"]']")
    end

    it "sets the list id value to the section id" do
      expect(rendered_component)
        .to have_css(".op-border-box-list[data-sortable-lists--list-id-value='#{section.id}']")
    end
  end
end
