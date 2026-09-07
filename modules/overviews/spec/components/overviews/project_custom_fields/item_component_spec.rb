# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Overviews::ProjectCustomFields::ItemComponent, type: :component do
  let(:project) { create(:project) }
  let(:section) { create(:project_custom_field_section) }
  let(:custom_field) do
    create(:string_project_custom_field,
           projects: [project],
           project_custom_field_section: section)
  end

  current_user { build_stubbed(:admin) }

  subject(:rendered_component) do
    create(:custom_value, customized: project, custom_field:, value:)
    render_inline(described_class.new(project:, project_custom_field: custom_field))
  end

  context "with a scalar field" do
    let(:value) { "Visible value" }

    it "renders the delegated value without truncation" do
      expect(rendered_component).to have_text(value)
      expect(rendered_component).to have_no_test_selector("expand-button")
    end
  end

  context "with a text field in the overview sidebar" do
    let(:custom_field) do
      create(:text_project_custom_field,
             projects: [project],
             project_custom_field_section: section)
    end
    let(:value) { ("Long text " * 100).strip }

    it "renders the delegated value as truncated, dialog-backed text" do
      expect(rendered_component).to have_css("[data-controller='expandable-text']", text: "Long text")
      expect(rendered_component).to have_test_selector("expand-button", visible: :all)
      expect(rendered_component.to_html).to include("openDialog")
    end
  end
end
